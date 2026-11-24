% =========================================================================
% Digital Signal Processing - Lecture 9, Lab 1: Image as a 2D Signal
% File: Lecture09_lab1_image_2d_signal.m
% Description: the lab script (sampling, quantization, histograms and
%   enhancement) with three additions:
%   - every figure is saved to figures/*.png for the README screenshots
%     (all at once at the end; a failed save only warns)
%   - the numbers used in the short reflections are printed
%   - Section 4 adds an antialiased downsampling for comparison, and the
%     optional Section 5 (moire) uses a synthetic zone-plate image
% Fix: the lab handout's fprintf line contained "I(smile)", an emoji that
%   replaced the colon operator; it is I(:) here.
% Requires: Image Processing Toolbox (rgb2gray, montage, imhist, imadjust,
%   mat2gray, imresize)
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

fprintf('MATLAB %s\n', version);
figList = cell(0, 2);   % {figure handle, file name}, saved at the end

%% 0) Load and inspect an image
if exist('peppers.png', 'file')
    I_rgb = imread('peppers.png');
    imageName = 'peppers.png';
else
    I_rgb = repmat(imread('cameraman.tif'), 1, 1, 3); % fallback
    imageName = 'cameraman.tif';
end
fig = figure; theme(fig, 'light');
imshow(I_rgb); title(['Original RGB: ' imageName]);
figList(end + 1, :) = {fig, 'fig0_original_rgb.png'};

% Convert to grayscale (luminance)
if size(I_rgb, 3) == 3
    I = rgb2gray(I_rgb);
else
    I = I_rgb;
end
fig = figure; theme(fig, 'light');
imshow(I); title('Grayscale (rgb2gray)');
figList(end + 1, :) = {fig, 'fig0_grayscale.png'};

% Basic info
fprintf('Image: %s\n', imageName);
fprintf('Class: %s | Range: [%g, %g] | Size: %d x %d\n', class(I), ...
    double(min(I(:))), double(max(I(:))), size(I, 1), size(I, 2));

%% 1) Quantization and dynamic range
I8 = I;                                 % 8-bit (0..255)
I6 = uint8(floor(double(I) / 4) * 4);   % ~6 bits (step 4)
I4 = uint8(floor(double(I) / 16) * 16); % ~4 bits (step 16)
fig = figure('Position', [100 100 1400 420]); theme(fig, 'light');
montage({I8, I6, I4}, 'Size', [1 3]);
title('Quantization: 8-bit vs ~6-bit vs ~4-bit');
figList(end + 1, :) = {fig, 'fig1_quantization.png'};

fprintf('Distinct grey levels used: 8-bit %d, ~6-bit %d, ~4-bit %d\n', ...
    numel(unique(I8)), numel(unique(I6)), numel(unique(I4)));
fprintf('Maximum quantization error: ~6-bit %d, ~4-bit %d grey levels\n', ...
    max(double(I8(:)) - double(I6(:))), max(double(I8(:)) - double(I4(:))));

%% 2) Histogram and contrast stretching
fig = figure('Position', [100 100 1100 400]); theme(fig, 'light');
subplot(1, 2, 1); imhist(I); title('Histogram (original)');
xlabel('Grey level'); ylabel('Pixel count');
I_norm = mat2gray(I);                       % scales to [0,1]
I_stretch = imadjust(I, [0.2 0.8], [0 1]);  % stretch mid-range
subplot(1, 2, 2); imhist(I_stretch); title('Histogram (stretched)');
xlabel('Grey level'); ylabel('Pixel count');
figList(end + 1, :) = {fig, 'fig2_histograms.png'};

fig = figure('Position', [100 100 1400 420]); theme(fig, 'light');
montage({I, im2uint8(I_norm), im2uint8(I_stretch)}, 'Size', [1 3]);
title('Original | Normalized | Contrast-stretched');
figList(end + 1, :) = {fig, 'fig2_contrast.png'};

% Inputs below 0.2*255 = 51 become 0 and inputs above 0.8*255 = 204 become 255.
lowCut = round(0.2 * 255);
highCut = round(0.8 * 255);
fprintf('Original range [%d, %d]; mat2gray maps it to [0, 255]\n', min(I(:)), max(I(:)));
fprintf('Stretch clips %.1f %% of pixels to 0 (input < %d) and %.1f %% to 255 (input > %d)\n', ...
    100 * mean(I(:) < lowCut), lowCut, 100 * mean(I(:) > highCut), highCut);
fprintf('Std of grey levels: original %.1f, stretched %.1f\n', ...
    std(double(I(:))), std(double(I_stretch(:))));
fprintf('Distinct grey levels: original %d, stretched %d (out of 256 possible)\n', ...
    numel(unique(I)), numel(unique(I_stretch)));

%% 3) Gamma correction (nonlinear amplitude scaling)
I_gamma_low = imadjust(I, [], [], 0.6);  % gamma < 1 brightens
I_gamma_high = imadjust(I, [], [], 1.6); % gamma > 1 darkens
fig = figure('Position', [100 100 1400 420]); theme(fig, 'light');
montage({I, I_gamma_low, I_gamma_high}, 'Size', [1 3]);
title('Gamma: original | gamma=0.6 | gamma=1.6');
figList(end + 1, :) = {fig, 'fig3_gamma.png'};

fprintf('Mean grey level: original %.1f, gamma 0.6 %.1f, gamma 1.6 %.1f\n', ...
    mean(double(I(:))), mean(double(I_gamma_low(:))), mean(double(I_gamma_high(:))));

%% 4) Sampling and aliasing (downsample then upsample)
scale = 0.1;                                % 10% of size
I_small = imresize(I, scale, 'nearest');    % naive sampling
I_back = imresize(I_small, size(I), 'nearest');
fig = figure('Position', [100 100 1400 420]); theme(fig, 'light');
montage({I, I_small, I_back}, 'Size', [1 3]);
title('Original | Aggressively downsampled | Upscaled back (aliasing artifacts)');
figList(end + 1, :) = {fig, 'fig4_sampling.png'};

fprintf('Downsampled size: %d x %d (from %d x %d)\n', ...
    size(I_small, 1), size(I_small, 2), size(I, 1), size(I, 2));

% Comparison (added): the same scale with imresize's default bicubic
% interpolation, which low-pass filters (antialiasing) before sampling.
I_small_aa = imresize(I, scale);
I_back_aa = imresize(I_small_aa, size(I), 'nearest');
fig = figure('Position', [100 100 1100 460]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(I_back); title('Nearest, no antialiasing (upscaled back)');
nexttile; imshow(I_back_aa); title('Bicubic with antialiasing (upscaled back)');
figList(end + 1, :) = {fig, 'fig4_antialiasing_comparison.png'};

%% 5) OPTIONAL: Moire demo
% peppers.png has no fine stripes, so a synthetic zone plate is used: a
% pattern of rings whose spatial frequency rises from 0 at the centre to
% 0.5 cycles/pixel (the Nyquist limit of the original grid) at the edge.
N = 512;
[x, y] = meshgrid(-N/2:N/2 - 1);
zonePlate = uint8(127.5 + 127.5 * cos(pi * (x.^2 + y.^2) / N));
zp_small = imresize(zonePlate, scale, 'nearest');
zp_small_aa = imresize(zonePlate, scale);

fig = figure('Position', [100 100 1400 470]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(zonePlate); title(sprintf('Zone plate %d x %d', N, N));
nexttile; imshow(imresize(zp_small, [N N], 'nearest')); title('10% nearest: moire rings');
nexttile; imshow(imresize(zp_small_aa, [N N], 'nearest')); title('10% with antialiasing');
figList(end + 1, :) = {fig, 'fig5_moire.png'};

% After sampling at 10 %, the new Nyquist limit is 0.05 cycles/pixel of the
% original grid. The zone plate reaches that frequency at this radius:
fprintf('Zone plate exceeds the new Nyquist limit beyond radius %.0f px (of %d)\n', ...
    0.05 * N, N / 2);

%% Save all figures (added)
% Saving at the end gives MATLAB Online time to finish rendering every
% figure. A figure that cannot be saved only produces a warning. No local
% functions are used, so the script also runs when pasted or run by section.
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

% One archive is easier to download from MATLAB Online than nine files.
zipFile = fullfile(scriptDir, 'figures.zip');
zip(zipFile, {saved.name}, figuresDir);
fprintf('All figures packed into %s\n', zipFile);

%% 6) Short reflections (add to your report)
% 1) Relate bit-depth to visible banding/posterization you observed.
% 2) How does contrast stretching change the histogram and visibility of details?
% 3) Explain why aggressive downsampling causes aliasing (reference Nyquist).
% The answers are in README.md.
