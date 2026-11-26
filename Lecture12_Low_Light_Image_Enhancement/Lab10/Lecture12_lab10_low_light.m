% =========================================================================
% Digital Signal Processing - Lecture 12, Lab 10: Learning to See in the
%   Dark (pretrained low-light enhancement network)
% File: Lecture12_lab10_low_light.m
% Description: the course demo script, run on our own dark image
%   (Example_03.png) instead of peppers.png, with one change:
%
%   CHANGE: darkFactor 0.03 -> 1.
%   Example_03.png is already a real low-light photo (mean brightness
%   0.046 on a 0..1 scale). The demo's darkFactor = 0.03 was meant for a
%   normally lit image such as peppers.png; on a dark photo it pushes the
%   signal down to about 0.0014 (0.35 of 255 grey levels), far below the
%   added noise (std sqrt(0.002) = 0.045), and the network has nothing
%   left to recover. With darkFactor = 1 the real dark photo goes into the
%   network as it is (plus the same noise).
%
% Additions that support the README (the network steps are unchanged):
%   - the input image is read from the folder of this script
%   - rng(42) before imnoise, so the noise and all numbers are reproducible
%   - the pipeline runs twice: lab default (0.03) and our change (1), and
%     then for a sweep of darkFactor values
%   - mean brightness and contrast (std) of every image are printed
%   - every figure is saved to figures/*.png and the enhanced result to
%     Example_03_enhanced.png (no local functions are used)
% Requires: Deep Learning Toolbox, Image Processing Toolbox.
% =========================================================================

clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
figuresDir = fullfile(scriptDir, 'figures');
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end

fprintf('MATLAB %s\n', version);

%% 1) Download pretrained network (only once)
% Use the same URL as in the MathWorks example.
dataDir = fullfile(tempdir, "Sony2025"); % or use pwd for current folder
if ~exist(dataDir, "dir")
    mkdir(dataDir);
end
modelFile = fullfile(dataDir, "trainedLowLightCameraPipelineNet.mat");
if ~isfile(modelFile)
    fprintf("Downloading pretrained low-light model...\n");
    % URL from the official example
    modelURL = "https://ssd.mathworks.com/supportfiles/" + ...
        "vision/data/trainedLowLightCameraPipelineDlnetwork.zip";
    zipFile = fullfile(dataDir, "trainedLowLightCameraPipelineDlnetwork.zip");
    % Download zip file
    websave(zipFile, modelURL);
    % Unzip to dataDir
    unzip(zipFile, dataDir);
    fprintf("Download complete. Model saved in:\n%s\n", dataDir);
end

%% 2) Load pretrained network
% The MAT file contains a variable called 'netTrained'.
load(modelFile, "netTrained");

%% 3) Read our own dark image (instead of peppers.png)
% I = imread("peppers.png");                       % lab default
I = imread(fullfile(scriptDir, "Example_03.png")); % our dark image
if size(I, 3) == 1
    I = repmat(I, 1, 1, 3); % the demo expects RGB
end
I = im2single(imresize(I, [512 512])); % Resize to 512x512 and convert to single
fprintf('Input: Example_03.png, mean %.3f, std %.3f\n', mean(I(:)), std(I(:)));

%% 4)-8) Simulate low light, build the fake RAW input, run the network
% The same steps as the demo, in a loop so the lab default and our change
% are run on the same image with the same noise.
noiseVar   = 0.002;            % unchanged: imnoise Gaussian variance
labDefault = 0.03;             % demo value
ourFactor  = 1;                % CHANGE: do not darken an already dark photo
sweep      = [0.03 0.1 0.3 1]; % extra: how the result depends on darkFactor
factors    = unique([labDefault ourFactor sweep]);

darkImgs = cell(1, numel(factors));
outImgs  = cell(1, numel(factors));
for k = 1:numel(factors)
    darkFactor = factors(k);

    % 4) Simulate a dark, noisy low-light image
    rng(42);                                               % added
    I_dark = I * darkFactor;                               % Reduce brightness
    I_dark_noisy = imnoise(I_dark, "gaussian", 0, noiseVar); % Add noise

    % 5) Build a simple 4-channel "fake RAW" input
    I_gray = rgb2gray(I_dark_noisy);   % H x W
    rawFake = repmat(I_gray, 1, 1, 4); % H x W x 4

    % 6) Wrap into dlarray with format "SSCB"
    input = dlarray(rawFake, "SSCB");
    if canUseGPU
        input = gpuArray(input);
    end

    % 7) Run the pretrained network
    out = predict(netTrained, input); % Output: H x W x 3 x 1 (RGB)

    % 8) Convert back to normal MATLAB image
    out = gather(extractdata(out)); % Remove dlarray and GPU
    out = squeeze(out);             % Remove batch dimension
    out = im2uint8(out);            % Convert to uint8 [0,255]

    darkImgs{k} = I_dark_noisy;
    outImgs{k}  = out;
    outD = im2double(out);
    fprintf(['darkFactor %.2f: network input mean %.4f (%.1f of 255 grey ' ...
        'levels), output mean %.3f, std %.3f, clipped %.1f%%\n'], ...
        darkFactor, mean(I_gray(:)), 255 * mean(I_gray(:)), ...
        mean(outD(:)), std(outD(:)), 100 * mean(out(:) == 255));
end

%% 9) Show original, low-light, and enhanced images side by side
% Figure 1: our change (darkFactor = 1). Figure 2: lab default (0.03).
showList = [ourFactor labDefault];
showName = {'fig1_our_change_darkFactor_1.png', 'fig2_lab_default_darkFactor_0_03.png'};
for s = 1:2
    k = find(factors == showList(s), 1);
    fig = figure('Position', [100 100 1500 520]);
    theme(fig, 'light');
    subplot(1,3,1);
    imshow(I);
    title("Original (Example\_03.png)");
    subplot(1,3,2);
    imshow(darkImgs{k});
    title(sprintf("Low light + noise (darkFactor = %g)", factors(k)));
    subplot(1,3,3);
    imshow(outImgs{k});
    title("Network output (enhanced)");
    drawnow;
    saveas(fig, fullfile(figuresDir, showName{s}));
end

% Figure 3: darkFactor sweep (network output for each value)
fig = figure('Position', [100 100 1600 460]);
theme(fig, 'light');
for s = 1:numel(sweep)
    k = find(factors == sweep(s), 1);
    subplot(1, numel(sweep), s);
    imshow(outImgs{k});
    title(sprintf("darkFactor = %g", sweep(s)));
end
sgtitle("Network output vs darkFactor (noise variance 0.002)");
drawnow;
saveas(fig, fullfile(figuresDir, 'fig3_darkFactor_sweep.png'));

% The enhanced result of our change, at full 512 x 512 resolution
imwrite(outImgs{factors == ourFactor}, fullfile(scriptDir, "Example_03_enhanced.png"));
fprintf('Saved figures to %s and Example_03_enhanced.png\n', figuresDir);
