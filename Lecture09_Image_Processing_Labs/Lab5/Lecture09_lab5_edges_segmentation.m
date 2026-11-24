% =========================================================================
% Digital Signal Processing - Lecture 9, Lab 5: Edge Detection and
%   Segmentation
% File: Lecture09_lab5_edges_segmentation.m
% Description: the lab script, unchanged in its computations, with
%   additions that support the screenshots and the reflections:
%   - every figure is saved to figures/*.png (all at once at the end;
%     a failed save only warns, and no local functions are used)
%   - edges vs high frequencies: where the high-pass energy lies
%   - the thresholds edge() chose, and edge-pixel and fragment counts
%   - a zoom comparing all four detectors, and the LoG response with its
%     zero crossings
%   - the histogram with the Otsu level and the between-class variance
%     that Otsu maximises, plus region-size statistics after labelling
% Requires: Image Processing Toolbox (edge, graythresh, imbinarize,
%   bwlabel, label2rgb, montage, fspecial, imfilter).
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

%% Lab 5: Edge Detection and Segmentation
I = im2double(rgb2gray(imread('peppers.png')));
fprintf('peppers.png: %d x %d, double in [0, 1]\n', size(I, 1), size(I, 2));

%% 1) Basic derivative filters (Sobel, Prewitt)
edges_sobel = edge(I, 'Sobel');
edges_prewitt = edge(I, 'Prewitt');
fig = figure('Position', [100 100 1200 460]); theme(fig, 'light');
montage({edges_sobel, edges_prewitt}, 'Size', [1 2]);
title('Sobel | Prewitt edges');
figList(end + 1, :) = {fig, 'fig1_sobel_prewitt.png'};

%% 2) Canny detector (multi-stage)
edges_canny = edge(I, 'Canny', [0.05 0.2]);
fig = figure; theme(fig, 'light');
imshow(edges_canny); title('Canny edges');
figList(end + 1, :) = {fig, 'fig2_canny.png'};

%% 3) Laplacian of Gaussian (LoG)
edges_log = edge(I, 'log');
fig = figure; theme(fig, 'light');
imshow(edges_log); title('Laplacian of Gaussian edges');
figList(end + 1, :) = {fig, 'fig3_log.png'};

% Added: the thresholds edge() chose automatically, and how many edge
% pixels and separate fragments each detector produced.
[~, tSobel] = edge(I, 'Sobel');
[~, tPrewitt] = edge(I, 'Prewitt');
[~, tLog] = edge(I, 'log');
fprintf('Automatic thresholds: Sobel %.4f, Prewitt %.4f, LoG %.4f; Canny set to [0.05 0.2]\n', ...
    tSobel, tPrewitt, tLog);

edgeMaps = {edges_sobel, edges_prewitt, edges_canny, edges_log};
edgeNames = {'Sobel', 'Prewitt', 'Canny', 'LoG'};
nPix = zeros(4, 1); nFrag = zeros(4, 1); nShort = zeros(4, 1); meanLen = zeros(4, 1);
for k = 1:4
    cc = bwconncomp(edgeMaps{k}, 8);
    len = cellfun(@numel, cc.PixelIdxList);
    nPix(k) = nnz(edgeMaps{k});
    nFrag(k) = cc.NumObjects;
    nShort(k) = sum(len < 10);
    meanLen(k) = mean(len);
end
disp(table(nPix, nFrag, nShort, round(meanLen, 1), 'RowNames', edgeNames, ...
    'VariableNames', {'EdgePixels', 'Fragments', 'FragmentsUnder10px', 'MeanFragmentLength'}));

% Thickness check: fraction of edge pixels that have an edge neighbour
% directly to the right AND directly below (a 2x2 block of edge pixels
% means the line is thicker than one pixel).
for k = 1:4
    E = edgeMaps{k};
    thick = E(1:end-1, 1:end-1) & E(2:end, 1:end-1) & E(1:end-1, 2:end) & E(2:end, 2:end);
    fprintf('%-8s 2x2 edge blocks: %d (%.2f %% of edge pixels)\n', edgeNames{k}, nnz(thick), 100 * nnz(thick) / nPix(k));
end

% Zoom on the white pepper and the garlic stem area for all four.
zr = 141:260; zc = 181:340;
fig = figure('Position', [100 100 1500 440]); theme(fig, 'light');
tiledlayout(1, 5, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(I(zr, zc)); title('Original, zoom');
for k = 1:4
    nexttile; imshow(edgeMaps{k}(zr, zc)); title(sprintf('%s (%d px)', edgeNames{k}, nPix(k)));
end
figList(end + 1, :) = {fig, 'fig3_zoom_all_detectors.png'};

% LoG response and its zero crossings (edge(I,'log') uses sigma = 2 and
% marks zero crossings whose slope exceeds the threshold).
hLog = fspecial('log', 13, 2);
R = imfilter(I, hLog, 'replicate');
zc_all = (R(1:end-1, 1:end-1) .* R(2:end, 1:end-1) < 0) | (R(1:end-1, 1:end-1) .* R(1:end-1, 2:end) < 0);
fig = figure('Position', [100 100 1500 440]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(R(zr, zc), [-0.05 0.05]); title('LoG response (grey = 0)');
nexttile; imshow(zc_all(zr(1:end-1), zc(1:end-1))); title('All zero crossings');
nexttile; imshow(edges_log(zr, zc)); title('edge(I, ''log''): strong ones only');
figList(end + 1, :) = {fig, 'fig3_log_zero_crossings.png'};
fprintf('LoG: all zero crossings %d px, kept by edge(I,''log'') %d px\n', nnz(zc_all), nPix(4));

% Edges vs high frequencies: high-pass = image minus a Gaussian blur.
% Share of the high-pass energy that lies on (dilated) Canny edge pixels.
HP = I - imgaussfilt(I, 2);
edgeZone = imdilate(edges_canny, strel('square', 3));
fprintf('Canny edge zone covers %.1f %% of the pixels but holds %.1f %% of the high-pass energy\n', ...
    100 * mean(edgeZone(:)), 100 * sum(HP(edgeZone).^2) / sum(HP(:).^2));
fig = figure('Position', [100 100 1200 460]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(abs(HP), [0 0.15]); title('|High-pass| = |I - Gaussian blur|');
nexttile; imshow(edges_canny); title('Canny edges');
figList(end + 1, :) = {fig, 'fig0_edges_vs_highpass.png'};

%% 4) Edge map -> segmentation (Otsu threshold)
level = graythresh(I); % Otsu method
BW = imbinarize(I, level);
fig = figure('Position', [100 100 1200 460]); theme(fig, 'light');
montage({I, BW}, 'Size', [1 2]);
title('Original | Otsu threshold binary mask');
figList(end + 1, :) = {fig, 'fig4_otsu.png'};

% Added: histogram with the Otsu level, and the between-class variance
% sigma_B^2(t) = w0(t) w1(t) (mu0(t) - mu1(t))^2 that Otsu maximises.
counts = imhist(I, 256);
p = counts / sum(counts);
levels = (0:255)' / 255;
w0 = cumsum(p);
mu = cumsum(p .* levels);
muT = mu(end);
sigmaB = (muT * w0 - mu).^2 ./ (w0 .* (1 - w0));
sigmaB(~isfinite(sigmaB)) = 0;
[~, iMax] = max(sigmaB);
fprintf('Otsu level %.4f (grey %.0f); maximum of sigma_B^2 at grey %d; foreground %.1f %% of pixels\n', ...
    level, 255 * level, iMax - 1, 100 * mean(BW(:)));

fig = figure('Position', [100 100 1100 440]); theme(fig, 'light');
yyaxis left;
bar(0:255, counts, 1, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
ylabel('Pixel count');
yyaxis right;
plot(0:255, sigmaB, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5);
ylabel('Between-class variance \sigma_B^2');
xline(255 * level, '--k', sprintf('Otsu = %.0f', 255 * level), 'LineWidth', 1.5);
xlim([0 255]); grid on; xlabel('Grey level');
title('Histogram, Otsu threshold and between-class variance');
figList(end + 1, :) = {fig, 'fig4_otsu_histogram.png'};

%% 5) Label and visualize regions
[L, num] = bwlabel(BW);
RGB = label2rgb(L);
fig = figure; theme(fig, 'light');
imshow(RGB); title(['Labeled regions: ', num2str(num)]);
figList(end + 1, :) = {fig, 'fig5_labels.png'};

% Added: region sizes. Many regions are only a few pixels large.
stats = regionprops(L, 'Area');
areas = sort([stats.Area], 'descend');
fprintf('Regions: %d; smaller than 10 px: %d; smaller than 100 px: %d; largest five: %s px\n', ...
    num, sum(areas < 10), sum(areas < 100), mat2str(areas(1:min(5, end))));
fprintf('The %d largest regions hold %.1f %% of the foreground pixels\n', ...
    min(5, num), 100 * sum(areas(1:min(5, end))) / sum(areas));

%% Save all figures (added)
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

%% 6) Reflections
% - Which operator gives the thinnest, cleanest edges?
% - Why does Canny outperform simple gradient filters?
% - How does Otsu relate to histogram-based thresholding?
% The answers are in README.md.
