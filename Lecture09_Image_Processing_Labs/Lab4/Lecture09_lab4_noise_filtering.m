% =========================================================================
% Digital Signal Processing - Lecture 9, Lab 4: Noise and Filtering
% File: Lecture09_lab4_noise_filtering.m
% Description: the lab script, unchanged in its computations, with
%   additions that support the screenshots and the reflections:
%   - rng(42) before imnoise, so the noise and all numbers are reproducible
%   - every figure is saved to figures/*.png (all at once at the end;
%     a failed save only warns, and no local functions are used)
%   - SNR and PSNR next to MSE (SNR is a learning outcome of the lab)
%   - a full table: every filter on both noise types, including the
%     Gaussian filter the lab computes but does not show, a median with
%     'symmetric' padding, and wiener2 as an example of an adaptive filter
%   - MSE split into edge and flat pixels, a zoom and a profile across an
%     edge, for the reflection on edge blurring
% Requires: Image Processing Toolbox (imnoise, immse, fspecial, imfilter,
%   medfilt2, wiener2, edge, montage).
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

%% Lab 4: Noise and Filtering
I = im2double(rgb2gray(imread('peppers.png')));
fprintf('peppers.png: %d x %d, double in [0, 1]\n', size(I, 1), size(I, 2));

% SNR in dB: signal power over error power. PSNR uses the peak value 1.
snrDb = @(J) 10 * log10(sum(I(:).^2) / sum((J(:) - I(:)).^2));

%% 1) Add different noise types
rng(42);   % added: reproducible noise
I_gauss = imnoise(I, 'gaussian', 0, 0.01);
I_sp = imnoise(I, 'salt & pepper', 0.05);
fig = figure('Position', [100 100 1500 420]); theme(fig, 'light');
montage({I, I_gauss, I_sp}, 'Size', [1 3]);
title('Original | Gaussian noise | Salt & pepper noise');
figList(end + 1, :) = {fig, 'fig1_noise.png'};

fprintf('Salt & pepper: %.2f %% of pixels set to 0 or 1 (density 0.05)\n', ...
    100 * mean(I_sp(:) ~= I(:) & (I_sp(:) == 0 | I_sp(:) == 1)));
fprintf('Gaussian noise: std of (noisy - original) = %.3f (sqrt(0.01) = 0.100 before clipping to [0, 1])\n', ...
    std(I_gauss(:) - I(:)));

%% 2) Compute simple quality metrics
MSE_gauss = immse(I_gauss, I);
MSE_sp = immse(I_sp, I);
fprintf('MSE Gaussian: %.4f | MSE S&P: %.4f\n', MSE_gauss, MSE_sp);
fprintf('SNR Gaussian: %.2f dB | SNR S&P: %.2f dB\n', snrDb(I_gauss), snrDb(I_sp));

%% 3) Linear filtering (mean, Gaussian)
h_avg = fspecial('average', 3);
I_avg_gauss = imfilter(I_gauss, h_avg, 'replicate');
I_avg_sp = imfilter(I_sp, h_avg, 'replicate');
h_gauss = fspecial('gaussian', [3 3], 0.7);
I_gauss_gauss = imfilter(I_gauss, h_gauss, 'replicate');

%% 4) Non-linear filtering (median)
I_med_gauss = medfilt2(I_gauss, [3 3]);
I_med_sp = medfilt2(I_sp, [3 3]);
fig = figure('Position', [100 100 1100 900]); theme(fig, 'light');
montage({I_avg_sp, I_med_sp, I_avg_gauss, I_med_gauss}, 'Size', [2 2]);
title('Top: Avg vs Median (S&P) | Bottom: Avg vs Median (Gaussian)');
figList(end + 1, :) = {fig, 'fig4_avg_vs_median.png'};

%% 5) Compare metrics after filtering
fprintf('After filtering, MSE S&P avg=%.4f, med=%.4f\n', ...
    immse(I_avg_sp, I), immse(I_med_sp, I));

% Added: every filter on both noise types. The Gaussian filter is also
% applied to the S&P image, the median is repeated with 'symmetric'
% padding (medfilt2 pads with zeros by default, which darkens the border),
% and wiener2 is included as an adaptive filter.
I_gauss_sp     = imfilter(I_sp, h_gauss, 'replicate');
I_medsym_gauss = medfilt2(I_gauss, [3 3], 'symmetric');
I_medsym_sp    = medfilt2(I_sp, [3 3], 'symmetric');
I_wien_gauss   = wiener2(I_gauss, [3 3]);
I_wien_sp      = wiener2(I_sp, [3 3]);

methodNames = {'Noisy (no filter)'; 'Mean 3x3'; 'Gaussian 3x3, sigma 0.7'; ...
    'Median 3x3 (zero padding)'; 'Median 3x3 (symmetric)'; 'wiener2 3x3 (adaptive)'};
resGauss = {I_gauss, I_avg_gauss, I_gauss_gauss, I_med_gauss, I_medsym_gauss, I_wien_gauss};
resSp    = {I_sp, I_avg_sp, I_gauss_sp, I_med_sp, I_medsym_sp, I_wien_sp};

nM = numel(methodNames);
mseG = zeros(nM, 1); snrG = zeros(nM, 1); psnrG = zeros(nM, 1);
mseS = zeros(nM, 1); snrS = zeros(nM, 1); psnrS = zeros(nM, 1);
for k = 1:nM
    mseG(k) = immse(resGauss{k}, I); snrG(k) = snrDb(resGauss{k}); psnrG(k) = psnr(resGauss{k}, I);
    mseS(k) = immse(resSp{k}, I);    snrS(k) = snrDb(resSp{k});    psnrS(k) = psnr(resSp{k}, I);
end
metrics = table(round(mseG, 5), round(snrG, 2), round(psnrG, 2), round(mseS, 5), round(snrS, 2), round(psnrS, 2), ...
    'RowNames', methodNames, ...
    'VariableNames', {'Gauss_MSE', 'Gauss_SNR_dB', 'Gauss_PSNR_dB', 'SP_MSE', 'SP_SNR_dB', 'SP_PSNR_dB'});
disp(metrics);

[~, bestG] = min(mseG(2:end));
[~, bestS] = min(mseS(2:end));
fprintf('Lowest MSE for Gaussian noise: %s; for salt & pepper: %s\n', methodNames{bestG + 1}, methodNames{bestS + 1});

% MSE split into edge pixels (Canny edges of the clean image, widened by
% one pixel) and flat pixels (everything else).
edgeMask = imdilate(edge(I, 'canny'), strel('square', 3));
fprintf('Edge pixels: %.1f %% of the image\n', 100 * mean(edgeMask(:)));
edgeMse = @(J) mean((J(edgeMask) - I(edgeMask)).^2);
flatMse = @(J) mean((J(~edgeMask) - I(~edgeMask)).^2);
fprintf('%-28s %12s %12s %12s %12s\n', 'Method', 'G edge MSE', 'G flat MSE', 'SP edge MSE', 'SP flat MSE');
for k = 1:nM
    fprintf('%-28s %12.5f %12.5f %12.5f %12.5f\n', methodNames{k}, ...
        edgeMse(resGauss{k}), flatMse(resGauss{k}), edgeMse(resSp{k}), flatMse(resSp{k}));
end

% Edge blurring on the clean image alone (no noise), so that the only
% error is the one the filter itself adds.
cleanMean = imfilter(I, h_avg, 'replicate');
cleanGaus = imfilter(I, h_gauss, 'replicate');
cleanMed  = medfilt2(I, [3 3], 'symmetric');
fprintf('Filtering the CLEAN image, edge-pixel MSE: mean %.5f, Gaussian %.5f, median %.5f\n', ...
    edgeMse(cleanMean), edgeMse(cleanGaus), edgeMse(cleanMed));

% Bar chart of PSNR for both noise types.
fig = figure('Position', [100 100 1100 480]); theme(fig, 'light');
b = bar(categorical(methodNames, methodNames), [psnrG psnrS]);
b(1).FaceColor = [0 0.4470 0.7410]; b(2).FaceColor = [0.8500 0.3250 0.0980];
grid on; ylim([0 max([psnrG; psnrS]) + 4]);
ylabel('PSNR (dB)'); title('PSNR against the original (higher is better)');
legend('Gaussian noise', 'Salt & pepper', 'Location', 'northwest');
figList(end + 1, :) = {fig, 'fig5_psnr.png'};

% Zoom on the garlic (bottom right) for both noise types.
zr = 236:335; zc = 400:499;
zoomG = {I, I_gauss, I_avg_gauss, I_gauss_gauss, I_medsym_gauss, I_wien_gauss};
zoomS = {I, I_sp, I_avg_sp, I_gauss_sp, I_medsym_sp, I_wien_sp};
zoomNames = {'Original', 'Noisy', 'Mean 3x3', 'Gaussian 3x3', 'Median 3x3', 'wiener2'};
fig = figure('Position', [100 100 1500 560]); theme(fig, 'light');
tiledlayout(2, 6, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:6
    nexttile; imshow(zoomG{k}(zr, zc)); title(zoomNames{k});
    if k == 1, ylabel('Gaussian noise'); set(gca, 'Visible', 'on', 'XTick', [], 'YTick', []); end
end
for k = 1:6
    nexttile; imshow(zoomS{k}(zr, zc)); title(zoomNames{k});
    if k == 1, ylabel('Salt & pepper'); set(gca, 'Visible', 'on', 'XTick', [], 'YTick', []); end
end
figList(end + 1, :) = {fig, 'fig5_zoom.png'};

% Profile across the garlic's left edge, filters applied to the clean
% image so that only the blurring is visible.
profRow = 300; pc = 395:440;
fig = figure; theme(fig, 'light');
plot(pc, I(profRow, pc), 'Color', [0.5 0.5 0.5], 'LineWidth', 2); hold on;
plot(pc, cleanMean(profRow, pc), 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5);
plot(pc, cleanGaus(profRow, pc), 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5);
plot(pc, cleanMed(profRow, pc), '--', 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.5); hold off;
grid on; xlim([pc(1) pc(end)]); ylim([0 1]);
xlabel('Column'); ylabel('Grey level');
title(sprintf('Clean image, row %d across the garlic edge', profRow));
legend('Original', 'Mean 3x3', 'Gaussian 3x3', 'Median 3x3', 'Location', 'northwest');
figList(end + 1, :) = {fig, 'fig5_edge_profile.png'};

% Border effect of medfilt2's default zero padding.
fig = figure('Position', [100 100 1000 430]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(I_med_sp(end - 39:end, 1:40), 'InitialMagnification', 'fit'); title('Median, zero padding (default)');
nexttile; imshow(I_medsym_sp(end - 39:end, 1:40), 'InitialMagnification', 'fit'); title('Median, symmetric padding');
figList(end + 1, :) = {fig, 'fig5_median_border.png'};

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
% - Which noise is best removed by median filter? Why?
% - Why does linear filtering blur edges more?
% - How could we design adaptive filters to preserve detail?
% The answers are in README.md.
