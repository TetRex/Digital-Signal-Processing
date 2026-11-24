% =========================================================================
% Digital Signal Processing - Lecture 10, Lab 8: Hybrid Traditional + AI
%   Pipeline (K-means segmentation + SqueezeNet classification)
% File: Lecture10_lab8_hybrid_pipeline.m
% Description: the lab script, unchanged in its computations, with
%   additions that test the lab's claim that segmenting first improves
%   the classification:
%   - rng(42) before imsegkmeans, so the clusters are reproducible
%   - every figure is saved to figures/*.png (all at once at the end;
%     a failed save only warns, and no local functions are used)
%   - which k-means cluster is really the object (cluster numbers are
%     arbitrary), measured by colour saturation (chroma)
%   - the top-5 classes for six inputs: the original image, the lab's
%     isolated object, the other cluster, a cleaned mask, a crop to the
%     object, and the cleaned mask cropped
% Requires: Image Processing Toolbox (imsegkmeans), Deep Learning Toolbox
%   and the Deep Learning Toolbox Model for SqueezeNet Network.
% =========================================================================

close all; clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
figuresDir = fullfile(scriptDir, 'figures');
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end
figList = cell(0, 2);   % {figure handle, file name}, saved at the end

fprintf('MATLAB %s\n', version);
rng(42);   % added: k-means starts from random centres

% Assignment Code: Hybrid Traditional + AI Pipeline
% ---------------------------------------------------
% Section 1: Load Image and AI Network
% ---------------------------------------------------
% Load a sample image of a flower
% We will try to classify the isolated flower using AI
targetImage = imread('peppers.png'); % Using a common sample image
% Load a pre-trained SqueezeNet network for classification (a small, fast CNN)
disp('Loading pre-trained AI network (SqueezeNet)...');
net = squeezenet;
disp('Network loaded.');
fig = figure('Name', 'Hybrid Pipeline Images', 'Position', [100 100 1100 820]); theme(fig, 'light');
subplot(2, 2, 1); imshow(targetImage); title('Original Image');

% ---------------------------------------------------
% Section 2: Traditional Method (Color Segmentation using K-Means)
% Role: Isolate the main object of interest using a traditional algorithm.
% ---------------------------------------------------
disp('Applying traditional color segmentation (K-Means)...');
% Reshape image for k-means clustering based on color
imgLab = rgb2lab(targetImage);
ab = imgLab(:, :, 2:3);
ab = im2single(ab);
pixelLabels = imsegkmeans(ab, 2); % Cluster into 2 colors
% Create a mask to isolate the main object (assuming the object is Cluster 2)
mask = pixelLabels == 2;
% Apply the mask to the original image to get the isolated flower area
isolatedObject = targetImage;
isolatedObject(repmat(~mask, 1, 1, 3)) = 0; % Set background pixels to black
subplot(2, 2, 2); imshow(mask); title('Traditional Mask (K-Means)');
subplot(2, 2, 3); imshow(isolatedObject); title('Isolated Object (Input to AI)');

% ---------------------------------------------------
% Section 3: AI Method (Image Classification)
% Role: Use deep learning to classify the isolated object.
% ---------------------------------------------------
disp('Running AI classification on the isolated object...');
% The AI network requires a specific input size (SqueezeNet needs 227x227x3)
inputSize = net.Layers(1).InputSize;
resizedObject = imresize(isolatedObject, [inputSize(1) inputSize(2)]);
% Classify the image using the pre-trained network
[YPred, probs] = classify(net, resizedObject);

% ---------------------------------------------------
% Section 4: Results Analysis
% ---------------------------------------------------
subplot(2, 2, 4); imshow(resizedObject); title('Resized Input to AI');
figList(end + 1, :) = {fig, 'fig1_lab_pipeline.png'};
fprintf('\n--- Hybrid Pipeline Results ---\n');
fprintf('The AI model classified the isolated object as: **%s**\n', string(YPred));
fprintf('Confidence (Probability): %.2f%%\n', max(probs)*100);
% The idea is that isolating the *object* first (traditional) helps the
% *classifier* (AI) focus purely on the target, improving accuracy
% compared to just feeding the original, complex background image into the AI.

%% Added: which cluster is the object?
% Cluster numbers from k-means are arbitrary. The peppers are strongly
% coloured, the background cloth is dark and grey, so the object cluster
% is the one with the larger mean chroma sqrt(a^2 + b^2).
chroma = hypot(imgLab(:, :, 2), imgLab(:, :, 3));
lightness = imgLab(:, :, 1);
for c = 1:2
    fprintf('Cluster %d: %.1f %% of pixels, mean chroma %.1f, mean lightness %.1f\n', c, ...
        100 * mean(pixelLabels(:) == c), mean(chroma(pixelLabels == c)), mean(lightness(pixelLabels == c)));
end
[~, objCluster] = max([mean(chroma(pixelLabels == 1)), mean(chroma(pixelLabels == 2))]);
fprintf('Object cluster by chroma: %d (the lab assumes 2)\n', objCluster);

fig = figure('Position', [100 100 1300 460]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(targetImage); title('Original');
nexttile; imshow(label2rgb(pixelLabels, [0 0.4470 0.7410; 0.8500 0.3250 0.0980])); title('K-means clusters: 1 blue, 2 orange');
nexttile; imshow(chroma, [0 80]); colorbar; title('Chroma \surd(a^2 + b^2)');
figList(end + 1, :) = {fig, 'fig2_clusters.png'};

%% Added: cleaned mask and crops
% Traditional post-processing of the object mask: fill holes, remove small
% blobs, keep the regions that together cover the object.
objMask = pixelLabels == objCluster;
cleanMask = imfill(imopen(objMask, strel('disk', 5)), 'holes');
cleanMask = bwareaopen(cleanMask, 500);
fprintf('Object mask: %.1f %% of pixels raw, %.1f %% after cleaning\n', 100 * mean(objMask(:)), 100 * mean(cleanMask(:)));

stats = regionprops(cleanMask, 'BoundingBox');
bb = stats(1).BoundingBox;
for k = 2:numel(stats)   % union of all bounding boxes
    b2 = stats(k).BoundingBox;
    x1 = min(bb(1), b2(1)); y1 = min(bb(2), b2(2));
    x2 = max(bb(1) + bb(3), b2(1) + b2(3)); y2 = max(bb(2) + bb(4), b2(2) + b2(4));
    bb = [x1 y1 x2 - x1 y2 - y1];
end
fprintf('Object bounding box: x %.0f-%.0f, y %.0f-%.0f (%.1f %% of the image area)\n', ...
    bb(1), bb(1) + bb(3), bb(2), bb(2) + bb(4), 100 * bb(3) * bb(4) / numel(objMask));

masked = @(m) targetImage .* uint8(repmat(m, 1, 1, 3));
otherCluster = 3 - objCluster;
variants = {targetImage, isolatedObject, masked(pixelLabels == otherCluster), masked(cleanMask), ...
    imcrop(targetImage, bb), imcrop(masked(cleanMask), bb)};
variantNames = {'Original (no segmentation)', 'Lab: cluster 2 isolated', ...
    sprintf('Other cluster (%d) isolated', otherCluster), 'Cleaned object mask', ...
    'Crop to object box', 'Cleaned mask + crop'};

classes = net.Layers(end).Classes;
top1 = strings(numel(variants), 1); top1P = zeros(numel(variants), 1); pepperP = zeros(numel(variants), 1);
pepperIdx = find(classes == 'bell pepper');
fig = figure('Position', [100 100 1500 760]); theme(fig, 'light');
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:numel(variants)
    X = imresize(variants{k}, inputSize(1:2));
    [Y, p] = classify(net, X);
    [ps, idx] = sort(p, 'descend');
    top1(k) = string(Y); top1P(k) = ps(1); pepperP(k) = p(pepperIdx);
    fprintf('\n%s:\n', variantNames{k});
    for t = 1:5
        fprintf('   %d. %-22s %6.2f %%\n', t, string(classes(idx(t))), 100 * ps(t));
    end
    nexttile; imshow(X);
    title(sprintf('%s\n%s %.1f %% | bell pepper %.1f %%', variantNames{k}, top1(k), 100 * ps(1), 100 * pepperP(k)));
end
figList(end + 1, :) = {fig, 'fig3_variants.png'};

disp(table(top1, round(100 * top1P, 2), round(100 * pepperP, 2), 'RowNames', variantNames, ...
    'VariableNames', {'Top1', 'Top1_percent', 'BellPepper_percent'}));

fig = figure('Position', [100 100 1100 460]); theme(fig, 'light');
b = bar(categorical(variantNames, variantNames), 100 * pepperP, 'FaceColor', [0.8500 0.3250 0.0980]);
grid on; ylim([0 100]); ylabel('P(bell pepper) (%)');
title('SqueezeNet probability of "bell pepper" for each input');
xtips = b.XEndPoints; ytips = b.YEndPoints;
text(xtips, ytips, compose('%.1f', 100 * pepperP), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
figList(end + 1, :) = {fig, 'fig4_pepper_probability.png'};

% Stability: k-means with 5 different seeds, does cluster 2 stay the object?
fprintf('\nK-means stability (cluster that is the object, for seeds 1-5): ');
for s = 1:5
    rng(s);
    L = imsegkmeans(ab, 2);
    [~, oc] = max([mean(chroma(L == 1)), mean(chroma(L == 2))]);
    fprintf('%d ', oc);
end
fprintf('\n');

%% Save all figures
% Saving at the end lets every figure finish rendering. A figure that
% cannot be saved only produces a warning.
drawnow;
for k = 1:size(figList, 1)
    [fig, name] = figList{k, :};
    outFile = fullfile(figuresDir, name);
    if ~isvalid(fig)
        warning('Figure for %s was closed before it could be saved.', name);
        continue;
    end
    try
        exportgraphics(fig, outFile, 'Resolution', 150);
    catch err
        warning('exportgraphics failed for %s (%s). Trying print instead.', name, err.message);
        try
            print(fig, outFile, '-dpng', '-r150');
        catch err2
            warning('Could not save %s: %s', name, err2.message);
        end
    end
end
fprintf('Saved figures in %s:\n', figuresDir);
saved = dir(fullfile(figuresDir, '*.png'));
for k = 1:numel(saved)
    fprintf('  %-34s %8d bytes\n', saved(k).name, saved(k).bytes);
end
