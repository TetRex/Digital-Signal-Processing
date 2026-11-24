% =========================================================================
% Digital Signal Processing - Lecture 10, Lab 7: Traditional Filters vs
%   AI Filters (Gaussian noise)
% File: Lecture10_lab7_traditional_vs_ai.m
% Description: the lab script, unchanged in its computations, with
%   additions that support the screenshots and the learning outcomes:
%   - rng(42) before imnoise, so the noise and all numbers are reproducible
%   - every figure is saved to figures/*.png (all at once at the end;
%     a failed save only warns, and no local functions are used)
%   - the mean, median and Gaussian-blur filters named in the learning
%     outcomes, and MSE next to PSNR and SSIM, for every method
%   - run time per method (timeit), zoomed crops and residual maps (what
%     each filter removed)
%   - a sweep over noise levels (sigma 0.02 to 0.15)
% Requires: Image Processing Toolbox and Deep Learning Toolbox (for the
%   pre-trained DnCNN: denoisingNetwork, denoiseImage).
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
rng(42);   % added: reproducible noise

% --- 1. Setup: Load an image and add Gaussian noise ---
% Read a sample image and convert to grayscale double format
originalImage = im2double(imread('cameraman.tif'));
% Define the noise standard deviation
noiseSigma = 0.04;
% Add Gaussian noise to the image
noisyImage = imnoise(originalImage, 'gaussian', 0, noiseSigma^2);
% Display the original and noisy images
fig = figure('Name', 'Gaussian Noise Denoising Comparison', 'Position', [100 100 1500 420]); theme(fig, 'light');
subplot(1, 4, 1); imshow(originalImage); title('Original Image');
subplot(1, 4, 2); imshow(noisyImage); title('Noisy Image');

% --- 2. Traditional Filter (Adaptive Wiener Filter) ---
% The Wiener filter is a traditional adaptive filter that performs well
% with additive white Gaussian noise. It adapts its smoothing level based
% on local variance, preserving edges better than a simple Gaussian blur.
% We provide the estimated noise variance for better results.
traditionalFiltered = wiener2(noisyImage, [5 5], noiseSigma^2);
% Display the result of the traditional filter
subplot(1, 4, 3); imshow(traditionalFiltered); title('Traditional (Wiener) Filter');

% --- 3. AI Filter (Pre-trained DnCNN) ---
% The pre-trained DnCNN network in MATLAB is specifically designed
% for grayscale images with Gaussian noise within a certain range.
% It automatically learns complex features to remove noise while
% preserving details.
% Load the pre-trained denoising CNN model
net = denoisingNetwork('DnCNN');
% Apply the deep learning filter
aiFiltered = denoiseImage(noisyImage, net);
% Display the result of the AI filter
subplot(1, 4, 4); imshow(aiFiltered); title('AI (DnCNN) Filter');
figList(end + 1, :) = {fig, 'fig1_lab_comparison.png'};

% --- 4. Quantitative Evaluation (PSNR and SSIM) ---
% Calculate PSNR (Peak Signal-to-Noise Ratio) and SSIM (Structural Similarity Index)
% Higher values indicate better quality.
psnrNoisy = psnr(noisyImage, originalImage);
ssimNoisy = ssim(noisyImage, originalImage);
psnrTraditional = psnr(traditionalFiltered, originalImage);
ssimTraditional = ssim(traditionalFiltered, originalImage);
psnrAI = psnr(aiFiltered, originalImage);
ssimAI = ssim(aiFiltered, originalImage);
% Display the metrics
fprintf('\n--- Image Quality Metrics Comparison ---\n');
fprintf('Method | PSNR (dB) | SSIM\n');
fprintf('----------------------|-----------|----------\n');
fprintf('Noisy Image | %8.4f | %8.4f\n', psnrNoisy, ssimNoisy);
fprintf('Traditional (Wiener) | %8.4f | %8.4f\n', psnrTraditional, ssimTraditional);
fprintf('AI (DnCNN) | %8.4f | %8.4f\n', psnrAI, ssimAI);

%% Added: mean, median and Gaussian blur, and MSE for every method
% The learning outcomes name these three filters and MSE; the lab code
% itself only compares Wiener and DnCNN with PSNR and SSIM.
meanFiltered   = imfilter(noisyImage, fspecial('average', 3), 'replicate');
medianFiltered = medfilt2(noisyImage, [3 3], 'symmetric');
gaussFiltered  = imgaussfilt(noisyImage, 1);

% Run time per method on this 256 x 256 image (CPU), measured with timeit,
% which repeats each call and excludes first-call overhead.
times = [0, timeit(@() imfilter(noisyImage, fspecial('average', 3), 'replicate')), ...
    timeit(@() medfilt2(noisyImage, [3 3], 'symmetric')), timeit(@() imgaussfilt(noisyImage, 1)), ...
    timeit(@() wiener2(noisyImage, [5 5], noiseSigma^2)), timeit(@() denoiseImage(noisyImage, net))];

methodNames = {'Noisy (no filter)'; 'Mean 3x3'; 'Median 3x3'; 'Gaussian blur sigma 1'; ...
    'Wiener 5x5 (adaptive)'; 'DnCNN (AI)'};
results = {noisyImage, meanFiltered, medianFiltered, gaussFiltered, traditionalFiltered, aiFiltered};

nM = numel(results);
mseV = zeros(nM, 1); psnrV = zeros(nM, 1); ssimV = zeros(nM, 1);
for k = 1:nM
    mseV(k) = immse(results{k}, originalImage);
    psnrV(k) = psnr(results{k}, originalImage);
    ssimV(k) = ssim(results{k}, originalImage);
end
fprintf('\n--- All methods, noise sigma = %.2f ---\n', noiseSigma);
disp(table(round(mseV, 6), round(psnrV, 2), round(ssimV, 4), round(1000 * times', 1), ...
    'RowNames', methodNames, 'VariableNames', {'MSE', 'PSNR_dB', 'SSIM', 'Time_ms'}));

fig = figure('Position', [100 100 1500 640]); theme(fig, 'light');
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:nM
    nexttile; imshow(results{k});
    title(sprintf('%s\nPSNR %.2f dB, SSIM %.3f', methodNames{k}, psnrV(k), ssimV(k)));
end
figList(end + 1, :) = {fig, 'fig2_all_methods.png'};

% Zoomed crops: the face and camera (detail) and the grass (texture).
cropRows = {31:130, 171:250};
cropCols = {81:180, 1:100};
cropNames = {'face and camera', 'grass'};
for c = 1:2
    fig = figure('Position', [100 100 1500 330]); theme(fig, 'light');
    tiledlayout(1, nM + 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    nexttile; imshow(originalImage(cropRows{c}, cropCols{c})); title('Original');
    for k = 1:nM
        nexttile; imshow(results{k}(cropRows{c}, cropCols{c})); title(methodNames{k});
    end
    figList(end + 1, :) = {fig, sprintf('fig3_zoom_%d_%s.png', c, strrep(cropNames{c}, ' ', '_'))};
end

% Residual maps: noisy minus filtered = what each filter removed. Ideally
% this is pure noise; visible outlines mean the filter also removed detail.
fig = figure('Position', [100 100 1500 330]); theme(fig, 'light');
tiledlayout(1, 6, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(noisyImage - originalImage, [-0.15 0.15]); title('True noise');
for k = 2:nM
    nexttile; imshow(noisyImage - results{k}, [-0.15 0.15]); title(['Removed: ' methodNames{k}]);
end
figList(end + 1, :) = {fig, 'fig4_residuals.png'};

% Correlation of each residual with the true noise (1 = removed exactly the
% noise) and with the original image's edges (detail that was removed).
trueNoise = noisyImage - originalImage;
gradMag = imgradient(originalImage);
fprintf('%-24s %18s %22s\n', 'Method', 'corr(removed, noise)', 'corr(|error|, edges)');
for k = 2:nM
    removed = noisyImage - results{k};
    err = abs(results{k} - originalImage);
    cN = corrcoef(removed(:), trueNoise(:));
    cE = corrcoef(err(:), gradMag(:));
    fprintf('%-24s %18.3f %22.3f\n', methodNames{k}, cN(1, 2), cE(1, 2));
end

%% Added: noise-level sweep
% The same comparison for several noise levels (each with its own seed).
sigmas = [0.02 0.04 0.08 0.15];
sweepPsnr = zeros(numel(sigmas), nM - 1);
sweepSsim = zeros(numel(sigmas), nM - 1);
for s = 1:numel(sigmas)
    rng(100 + s);
    Ns = imnoise(originalImage, 'gaussian', 0, sigmas(s)^2);
    outs = {imfilter(Ns, fspecial('average', 3), 'replicate'), medfilt2(Ns, [3 3], 'symmetric'), ...
        imgaussfilt(Ns, 1), wiener2(Ns, [5 5], sigmas(s)^2), denoiseImage(Ns, net)};
    for k = 1:numel(outs)
        sweepPsnr(s, k) = psnr(outs{k}, originalImage);
        sweepSsim(s, k) = ssim(outs{k}, originalImage);
    end
    fprintf('sigma %.2f: noisy PSNR %.2f dB | best %s (%.2f dB)\n', sigmas(s), psnr(Ns, originalImage), ...
        methodNames{find(sweepPsnr(s, :) == max(sweepPsnr(s, :)), 1) + 1}, max(sweepPsnr(s, :)));
end
disp('PSNR (dB) per noise sigma (rows) and method (columns):');
disp(array2table(round(sweepPsnr, 2), 'RowNames', compose('sigma %.2f', sigmas'), ...
    'VariableNames', {'Mean', 'Median', 'Gaussian', 'Wiener', 'DnCNN'}));
disp('SSIM per noise sigma (rows) and method (columns):');
disp(array2table(round(sweepSsim, 4), 'RowNames', compose('sigma %.2f', sigmas'), ...
    'VariableNames', {'Mean', 'Median', 'Gaussian', 'Wiener', 'DnCNN'}));

colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
fig = figure('Position', [100 100 1300 480]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; hold on;
for k = 1:5
    plot(sigmas, sweepPsnr(:, k), '-o', 'Color', colors(k, :), 'LineWidth', 1.5);
end
hold off; grid on; xlim([0 0.16]); ylim([floor(min(sweepPsnr(:))) - 1, ceil(max(sweepPsnr(:))) + 1]);
xlabel('Noise standard deviation \sigma'); ylabel('PSNR (dB)'); title('PSNR vs noise level');
legend(methodNames(2:end), 'Location', 'northeast');
nexttile; hold on;
for k = 1:5
    plot(sigmas, sweepSsim(:, k), '-o', 'Color', colors(k, :), 'LineWidth', 1.5);
end
hold off; grid on; xlim([0 0.16]); ylim([0 1]);
xlabel('Noise standard deviation \sigma'); ylabel('SSIM'); title('SSIM vs noise level');
figList(end + 1, :) = {fig, 'fig5_noise_sweep.png'};

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

% --- 5. Visual Observation ---
% The output will show that the Wiener filter does a good job of smoothing,
% but the AI-based DnCNN filter typically yields higher PSNR and SSIM values
% and better visual results by preserving fine details and texture more effectively
% than traditional methods.
% The observations for this run are in README.md.
