% =========================================================================
% Digital Signal Processing - Lecture 9, Lab 6: Mini Project
% File: Lecture09_lab6_mini_project.m
% Problem: printedtext.png is a photo of a printed page under strongly
%   uneven light (the left side is almost black, the right side bright).
%   One global Otsu threshold turns the left half black and washes out
%   text on the right. Goal: make the text readable everywhere and
%   produce a clean binary page for OCR.
% Pipeline (the lab template's stages, adapted to this problem):
%   1) Pre-process: 3x3 median filter (specks and sensor noise)
%   2) Illumination estimate in the frequency domain: closing removes the
%      text, a Gaussian low-pass applied with fft2 smooths the background;
%      the image is divided by it (illumination is multiplicative)
%   3) Contrast enhancement with an automatic window (stretchlim)
%   4) Otsu threshold on the corrected image (vs on the raw image)
%   5) Canny edges of the characters (raw vs corrected)
%   - every figure is saved to figures/*.png (all at once at the end;
%     a failed save only warns, and no local functions are used)
% Requires: Image Processing Toolbox (medfilt2, imclose, strel, imadjust,
%   stretchlim, graythresh, imbinarize, adaptthresh, edge, bwconncomp,
%   padarray, montage).
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

%% 1) Load the image and state the problem
I0 = imread('printedtext.png');
if size(I0, 3) == 3
    I0 = rgb2gray(I0);
end
I = im2double(I0);
[M, N] = size(I);
fprintf('printedtext.png: %d x %d, range [%.3f, %.3f]\n', M, N, min(I(:)), max(I(:)));

% Page brightness in the three vertical thirds of the image.
thirds = {1:floor(N/3), floor(N/3) + 1:floor(2*N/3), floor(2*N/3) + 1:N};
thirdNames = {'left', 'middle', 'right'};
for t = 1:3
    fprintf('Mean brightness, %-6s third: %.3f\n', thirdNames{t}, mean(mean(I(:, thirds{t}))));
end

% The naive approach: one global Otsu threshold on the raw image.
levelRaw = graythresh(I);
[~, emRaw] = graythresh(I);
BW_raw = imbinarize(I, levelRaw);

fig = figure('Position', [100 100 1500 420]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(I); title('Original');
nexttile; [cnt, lv] = imhist(I); bar(lv, cnt, 1, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
xlim([0 1]); grid on; title('Histogram'); xlabel('Grey level'); ylabel('Pixel count');
nexttile; imshow(BW_raw); title(sprintf('Global Otsu on the raw image (level %.3f)', levelRaw));
figList(end + 1, :) = {fig, 'fig1_problem.png'};

%% 2) Pre-process: noise removal (median 3x3)
I_filt = medfilt2(I, [3 3], 'symmetric');
resid = I - I_filt;
fprintf('Median filter: %.1f %% of pixels unchanged, %.1f %% changed by more than 0.02 (5 grey levels)\n', ...
    100 * mean(resid(:) == 0), 100 * mean(abs(resid(:)) > 0.02));

zr = 520:640; zc = 40:300;   % dark text in the left third
fig = figure('Position', [100 100 1300 400]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(I(zr, zc), []); title('Raw, dark left region (contrast stretched)');
nexttile; imshow(I_filt(zr, zc), []); title('After median 3x3 (same stretch)');
figList(end + 1, :) = {fig, 'fig2_denoise_zoom.png'};

%% 3) Illumination estimate in the frequency domain
% Model: I = illumination x reflectance. Illumination varies slowly
% (low frequencies); text is small and dark (high frequencies).
% a) Grey-level closing with a disk larger than the stroke width removes
%    the dark text and leaves the paper brightness.
% b) A Gaussian low-pass with fft2 smooths that estimate. The image is
%    padded symmetrically first, because the FFT treats the image as
%    periodic and would otherwise mix the dark left edge with the bright
%    right edge.
closed = imclose(I_filt, strel('disk', 15));

sigmaS = 30;                       % spatial width of the low-pass in px
pad = 3 * sigmaS;
P = padarray(closed, [pad pad], 'symmetric');
[Mp, Np] = size(P);
[u, v] = meshgrid((-floor(Np/2)):(ceil(Np/2) - 1), (-floor(Mp/2)):(ceil(Mp/2) - 1));
H = exp(-2 * pi^2 * sigmaS^2 * ((u / Np).^2 + (v / Mp).^2));   % Gaussian LP, sigma = 30 px
Pf = real(ifft2(ifftshift(fftshift(fft2(P)) .* H)));
B = Pf(pad + 1:pad + M, pad + 1:pad + N);                      % background (illumination)

I_corr = I_filt ./ max(B, 0.02);
fprintf('Background estimate range [%.3f, %.3f] (ratio %.1f : 1)\n', min(B(:)), max(B(:)), max(B(:)) / min(B(:)));
fprintf('Low-pass keeps frequencies up to about %.4f cycles/pixel (H = 0.5)\n', sqrt(log(2) / (2 * pi^2 * sigmaS^2)));

fig = figure('Position', [100 100 1500 420]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(closed); title('a) Closing, disk 15: text removed');
nexttile; imshow(B); title(sprintf('b) FFT Gaussian LP, \\sigma = %d px: illumination', sigmaS));
nexttile; imshow(I_corr, [0 1.2]); title('I / illumination: flat page');
figList(end + 1, :) = {fig, 'fig3_illumination.png'};

% Frequency view: spectrum of the padded background with the mask.
fig = figure('Position', [100 100 1100 420]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(log(1 + abs(fftshift(fft2(padarray(I_filt, [pad pad], 'symmetric'))))), []);
title('Log spectrum of the (padded) page');
xlim(Np/2 + [-150 150]); ylim(Mp/2 + [-150 150]);
nexttile; imshow(H, []); title('Gaussian LP mask H(u,v), centre');
xlim(Np/2 + [-150 150]); ylim(Mp/2 + [-150 150]);
figList(end + 1, :) = {fig, 'fig3_spectrum_mask.png'};

% Profile along one text row: raw, background, corrected.
profRow = 600;
fig = figure; theme(fig, 'light');
plot(1:N, I_filt(profRow, :), 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8); hold on;
plot(1:N, B(profRow, :), 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 2);
plot(1:N, min(I_corr(profRow, :), 1.3), 'Color', [0 0.4470 0.7410], 'LineWidth', 0.8); hold off;
grid on; xlim([1 N]); ylim([0 1.3]);
xlabel('Column'); ylabel('Grey level');
title(sprintf('Row %d: raw (grey), illumination (orange), corrected (blue)', profRow));
legend('Median-filtered image', 'Illumination estimate', 'Corrected', 'Location', 'northwest');
figList(end + 1, :) = {fig, 'fig3_profile.png'};

%% 4) Enhance contrast (automatic window)
% The template's fixed window [0.2 0.8] does not fit this image after
% correction (the paper is near 1); stretchlim picks the window from the
% 1st and 99th percentiles instead.
lims = stretchlim(min(I_corr, 1), [0.01 0.99]);
I_enh = imadjust(min(I_corr, 1), lims, [0 1]);
fprintf('Contrast window from stretchlim: [%.3f, %.3f]\n', lims(1), lims(2));

fig = figure('Position', [100 100 1300 420]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; [cnt, lv] = imhist(min(I_corr, 1)); bar(lv, cnt, 1, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
xlim([0 1]); grid on; title('Histogram after illumination correction'); xlabel('Grey level'); ylabel('Pixel count');
nexttile; [cnt, lv] = imhist(I_enh); bar(lv, cnt, 1, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
xlim([0 1]); grid on; title('Histogram after contrast stretching'); xlabel('Grey level'); ylabel('Pixel count');
figList(end + 1, :) = {fig, 'fig4_histograms.png'};

%% 5) Segment: Otsu on the corrected page
levelCorr = graythresh(I_enh);
[~, emCorr] = graythresh(I_enh);
BW_corr = imbinarize(I_enh, levelCorr);
BW_corr = ~bwareaopen(~BW_corr, 5);        % drop ink specks smaller than 5 px
BW_adapt = imbinarize(I, adaptthresh(I, 0.5, 'ForegroundPolarity', 'dark'));   % reference

fprintf('Otsu on raw: level %.3f, effectiveness %.3f | on corrected: level %.3f, effectiveness %.3f\n', ...
    levelRaw, emRaw, levelCorr, emCorr);

paper = BW_corr;   % paper pixels according to the final mask
cvRaw = std(I(paper)) / mean(I(paper));
cvCorr = std(I_corr(paper)) / mean(I_corr(paper));
fprintf('Paper brightness variation (std/mean): raw %.3f, corrected %.3f\n', cvRaw, cvCorr);

fprintf('%-8s %12s %12s %12s %14s %14s\n', 'Third', 'Ink raw %', 'Ink corr %', 'Ink adapt %', 'Chars raw', 'Chars corr');
for t = 1:3
    c = thirds{t};
    ccRaw = bwconncomp(~BW_raw(:, c));
    ccCorr = bwconncomp(~BW_corr(:, c));
    fprintf('%-8s %12.1f %12.1f %12.1f %14d %14d\n', thirdNames{t}, ...
        100 * mean(mean(~BW_raw(:, c))), 100 * mean(mean(~BW_corr(:, c))), 100 * mean(mean(~BW_adapt(:, c))), ...
        ccRaw.NumObjects, ccCorr.NumObjects);
end

fig = figure('Position', [100 100 1500 420]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(BW_raw); title('Otsu on the raw image');
nexttile; imshow(BW_corr); title('Otsu after the pipeline');
nexttile; imshow(BW_adapt); title('Reference: adaptthresh on the raw image');
figList(end + 1, :) = {fig, 'fig5_binarization.png'};

% Zoom on the dark left part.
zr2 = 140:250; zc2 = 60:560;
fig = figure('Position', [100 100 1500 330]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(I(zr2, zc2)); title('Raw, dark left part');
nexttile; imshow(I_enh(zr2, zc2)); title('After correction + contrast');
nexttile; imshow(BW_corr(zr2, zc2)); title('Binary page (Otsu after pipeline)');
figList(end + 1, :) = {fig, 'fig5_zoom_left.png'};

% Texture check: edge pixels on paper only (away from ink) in the left
% third, where dividing by a dark background amplifies paper grain.
inkZone = imdilate(~BW_corr, strel('disk', 3));

%% 6) Extract features: Canny edges of the characters
edges_raw = edge(I, 'Canny', [0.1 0.25]);
edges = edge(I_enh, 'Canny', [0.1 0.25]);
fprintf('Canny edge pixels on paper (not near ink), pipeline: ');
for t = 1:3
    e = edges(:, thirds{t}) & ~inkZone(:, thirds{t});
    fprintf('%s %d (%.1f %%)   ', thirdNames{t}, nnz(e), 100 * nnz(e) / max(nnz(edges(:, thirds{t})), 1));
end
fprintf('\n');
fprintf('Canny edge pixels per third (raw -> pipeline): ');
for t = 1:3
    fprintf('%s %d -> %d   ', thirdNames{t}, nnz(edges_raw(:, thirds{t})), nnz(edges(:, thirds{t})));
end
fprintf('\n');

fig = figure('Position', [100 100 1300 420]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(edges_raw); title('Canny on the raw image');
nexttile; imshow(edges); title('Canny after the pipeline');
figList(end + 1, :) = {fig, 'fig6_edges.png'};

%% 7) Visualization: the whole pipeline (template layout)
% Shown as a 2 x 3 grid; the 1-pixel Canny lines are widened to 3 px for
% display only, because they vanish when the page is shrunk on screen.
fig = figure('Position', [100 100 1500 640]); theme(fig, 'light');
montage({I, I_filt, B, I_enh, BW_corr, ~imdilate(edges, strel('square', 3))}, 'Size', [2 3]);
title('Top: original | median 3x3 | illumination (FFT LP)    Bottom: corrected + enhanced | Otsu | Canny (widened)');
figList(end + 1, :) = {fig, 'fig7_pipeline.png'};

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

%% 8) Report
% - Describe your processing pipeline.
% - Explain how each stage relates to DSP operations.
% - Discuss improvements or limitations.
% The report is in README.md.
