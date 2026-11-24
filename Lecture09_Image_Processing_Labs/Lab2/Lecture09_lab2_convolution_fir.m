% =========================================================================
% Digital Signal Processing - Lecture 9, Lab 2: 2D Convolution & FIR
%   Filters (Blur, Sharpen, Edges)
% File: Lecture09_lab2_convolution_fir.m
% Description: the lab script, unchanged in its computations, with
%   additions that support the screenshots and the reflections:
%   - every figure is saved to figures/*.png (all at once at the end;
%     a failed save only warns, and no local functions are used)
%   - Section 1: zoom on the 3x3 impulse response and the Gaussian one
%   - Section 2: frequency response of box vs Gaussian, and the cost and
%     run time of a 2D kernel vs two separable 1D passes
%   - Section 3: the high-frequency mask shown with mat2gray as well
%   - Section 5: an asymmetric kernel, where convolution and correlation
%     differ (the box kernel is symmetric, so they cannot)
%   - Section 6: corner zoom and border differences between the modes
% Requires: Image Processing Toolbox (fspecial, imfilter, montage,
%   mat2gray); conv2, fft and timeit are base MATLAB.
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

if exist('peppers.png', 'file')
    I0 = imread('peppers.png');
else
    I0 = repmat(imread('cameraman.tif'), 1, 1, 3);
end
I = im2double(rgb2gray(I0));
fprintf('Image: %d x %d, double in [0, 1]\n', size(I, 1), size(I, 2));

%% 1) Delta image & impulse response
delta = zeros(101, 101); delta(51, 51) = 1;
h_avg = ones(3, 3) / 9;
H_vis = conv2(delta, h_avg, 'same');
fig = figure; theme(fig, 'light');
imagesc(H_vis); axis image off; colorbar; title('Impulse response of 3x3 average');
figList(end + 1, :) = {fig, 'fig1_impulse_response.png'};

% Added: zoom on the centre, and the impulse response of the Gaussian
% kernel from Section 2 (sigma 1.2, 7x7) for comparison.
g1d_vis = fspecial('gaussian', [1 7], 1.2);
H_gauss_vis = conv2(delta, g1d_vis' * g1d_vis, 'same');
fig = figure('Position', [100 100 1000 430]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
imagesc(46:56, 46:56, H_vis(46:56, 46:56)); axis image; colorbar;
title('3x3 average, zoom (11 x 11)'); xlabel('n'); ylabel('m');
nexttile;
imagesc(46:56, 46:56, H_gauss_vis(46:56, 46:56)); axis image; colorbar;
title('7x7 Gaussian \sigma = 1.2, zoom'); xlabel('n'); ylabel('m');
figList(end + 1, :) = {fig, 'fig1_impulse_response_zoom.png'};

fprintf('Impulse response sums: average %.4f, Gaussian %.4f\n', sum(H_vis(:)), sum(H_gauss_vis(:)));

%% 2) Low-pass: box vs Gaussian, separability
h_box3 = ones(3, 3) / 9;
h_box7 = ones(7, 7) / 49;
sigma = 1.2;
g1d = fspecial('gaussian', [1 7], sigma);
h_gauss = g1d' * g1d; % separable
I_box3 = imfilter(I, h_box3, 'replicate');
I_box7 = imfilter(I, h_box7, 'replicate');
I_gauss = imfilter(I, h_gauss, 'replicate');
fig = figure('Position', [100 100 1600 380]); theme(fig, 'light');
montage({I, I_box3, I_box7, I_gauss}, 'Size', [1 4]);
title('Original | Box 3x3 | Box 7x7 | Gaussian (separable)');
figList(end + 1, :) = {fig, 'fig2_lowpass.png'};

% Added: 1D frequency response of the 7-tap box and the 7-tap Gaussian
% (the 2D responses are products of these, because both are separable).
nfft = 1024;
f = (0:nfft/2) / nfft;                          % cycles/pixel, 0 to 0.5
Hbox = abs(fft(ones(1, 7) / 7, nfft));
Hgau = abs(fft(g1d, nfft));
Hbox = Hbox(1:nfft/2 + 1);
Hgau = Hgau(1:nfft/2 + 1);
fig = figure; theme(fig, 'light');
plot(f, 20 * log10(Hbox + eps), 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5); hold on;
plot(f, 20 * log10(Hgau + eps), 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5); hold off;
grid on; xlim([0 0.5]); ylim([-80 5]);
xlabel('Frequency (cycles/pixel)'); ylabel('|H| (dB)');
title('1D frequency response: 7-tap box vs 7-tap Gaussian (\sigma = 1.2)');
legend('Box 7', 'Gaussian 7', 'Location', 'southwest');
figList(end + 1, :) = {fig, 'fig2_frequency_response.png'};

% First sidelobe of the box: the largest |H| after its first zero (1/7).
sidelobe = max(Hbox(f > 1/7 + 0.01));
fprintf('Box 7: first zero at %.3f cycles/pixel, highest sidelobe %.1f dB\n', 1/7, 20 * log10(sidelobe));
% Truncating the Gaussian to 7 taps adds one tiny notch near 0.475
% cycles/pixel, more than 60 dB down; below 0.45 it decreases steadily.
fprintf('Gaussian 7: |H| at 0.25 cycles/pixel %.1f dB, at 0.5 cycles/pixel %.1f dB; steadily decreasing up to 0.45: %d\n', ...
    20 * log10(Hgau(f == 0.25)), 20 * log10(Hgau(end)), all(diff(Hgau(f <= 0.45)) < 0));
fprintf('Spread (standard deviation) of the 7-tap box %.2f px vs Gaussian sigma %.2f px\n', ...
    sqrt((7^2 - 1) / 12), sigma);

% Added: separability. A k x k kernel needs k^2 multiplications per pixel;
% two 1D passes need 2k. Timed with conv2 for a large Gaussian (k = 31).
k = 31;
g1d_big = fspecial('gaussian', [1 k], 5);
h_big = g1d_big' * g1d_big;
t2d  = timeit(@() conv2(I, h_big, 'same'));
tsep = timeit(@() conv2(g1d_big', g1d_big, I, 'same'));
sepDiff = max(max(abs(conv2(I, h_big, 'same') - conv2(g1d_big', g1d_big, I, 'same'))));
fprintf('Multiplications per pixel: 7x7 kernel %d vs separable %d; 31x31 kernel %d vs separable %d\n', ...
    7^2, 2*7, k^2, 2*k);
fprintf('Run time for k = %d: 2D conv2 %.2f ms, separable conv2 %.2f ms (%.1fx faster), max difference %.2g\n', ...
    k, 1000 * t2d, 1000 * tsep, t2d / tsep, sepDiff);

%% 3) Unsharp masking (sharpen)
I_blur = imfilter(I, h_gauss, 'replicate');
mask = I - I_blur; % high-frequency
gain = 1.0;
I_sharp = max(min(I + gain * mask, 1), 0);
fig = figure('Position', [100 100 1600 380]); theme(fig, 'light');
montage({I, I_blur, mask, I_sharp}, 'Size', [1 4]);
title('Original | Blur | High-freq mask | Sharpened');
figList(end + 1, :) = {fig, 'fig3_unsharp.png'};

% Added: the mask has negative values, which montage shows as black.
% mat2gray maps it to [0, 1] so that 0 becomes mid-grey.
fig = figure('Position', [100 100 1100 430]); theme(fig, 'light');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(mat2gray(mask)); title('High-freq mask, mat2gray (grey = 0)');
nexttile; imshow(I_sharp(101:228, 201:328)); title('Sharpened, zoom 128 x 128');
figList(end + 1, :) = {fig, 'fig3_mask_scaled.png'};

fprintf('Mask range [%.3f, %.3f], %.1f %% of pixels negative\n', min(mask(:)), max(mask(:)), 100 * mean(mask(:) < 0));
fprintf('Sharpened image clipped at 0 or 1: %.2f %% of pixels\n', ...
    100 * mean((I(:) + gain * mask(:)) < 0 | (I(:) + gain * mask(:)) > 1));

%% 4) Edges: Sobel & Laplacian
h_sobel_x = fspecial('sobel');
h_sobel_y = h_sobel_x';
Gx = imfilter(I, h_sobel_x, 'replicate');
Gy = imfilter(I, h_sobel_y, 'replicate');
Gmag = hypot(Gx, Gy);
h_lap = fspecial('laplacian', 0.2);
I_lap = imfilter(I, h_lap, 'replicate');
fig = figure('Position', [100 100 1600 380]); theme(fig, 'light');
montage({mat2gray(Gx), mat2gray(Gy), mat2gray(Gmag), mat2gray(I_lap)}, 'Size', [1 4]);
title('Sobel Gx | Sobel Gy | Gradient magnitude | Laplacian');
figList(end + 1, :) = {fig, 'fig4_edges.png'};

disp('fspecial(''sobel'') = '); disp(h_sobel_x);
disp('fspecial(''laplacian'', 0.2) = '); disp(round(h_lap, 4));
fprintf('Kernel sums: Sobel %g, Laplacian %g (zero DC gain)\n', sum(h_sobel_x(:)), sum(h_lap(:)));

%% 5) Correlation vs convolution (kernel flip)
C1 = conv2(I, h_box3, 'same');
C2 = imfilter(I, h_box3, 'conv', 'same'); % 'conv' flips internally
diff_val = max(abs(C1(:) - C2(:)));
fprintf('Max difference (conv2 vs imfilter with conv): %g\n', diff_val);

% Added: the box kernel is symmetric, so flipping it changes nothing.
% With the asymmetric Sobel kernel, correlation and convolution differ:
% the 180-degree flip turns the kernel into its negative.
S_corr = imfilter(I, h_sobel_x, 'corr', 'replicate');
S_conv = imfilter(I, h_sobel_x, 'conv', 'replicate');
fprintf('Box 3x3 is symmetric: isequal(h, rot90(h, 2)) = %d\n', isequal(h_box3, rot90(h_box3, 2)));
fprintf('Sobel: max |corr - conv| = %.3f, max |corr + conv| = %.2g (conv = -corr)\n', ...
    max(abs(S_corr(:) - S_conv(:))), max(abs(S_corr(:) + S_conv(:))));

%% 6) Boundary handling
I_rep = imfilter(I, h_box7, 'replicate');
I_sym = imfilter(I, h_box7, 'symmetric');
I_cir = imfilter(I, h_box7, 'circular');
fig = figure('Position', [100 100 1400 400]); theme(fig, 'light');
montage({I_rep, I_sym, I_cir}, 'Size', [1 3]);
title('Boundary: replicate | symmetric | circular');
figList(end + 1, :) = {fig, 'fig6_boundary.png'};

% Added: the modes differ only within 3 pixels (half the 7x7 kernel) of
% the border, so a zoom on the bottom-left corner shows the difference.
% 'zeros' (imfilter's default) is included for comparison.
I_zero = imfilter(I, h_box7);   % zero padding
rows = size(I, 1) - 23:size(I, 1);
cols = 1:24;
modes = {I_zero, I_rep, I_sym, I_cir};
modeNames = {'zeros (default)', 'replicate', 'symmetric', 'circular'};
fig = figure('Position', [100 100 1400 400]); theme(fig, 'light');
tiledlayout(1, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:numel(modes)
    nexttile;
    imshow(modes{k}(rows, cols), [0 1], 'InitialMagnification', 'fit');
    title(sprintf('%s\nbottom-left 24 x 24', modeNames{k}));
end
figList(end + 1, :) = {fig, 'fig6_boundary_corner.png'};

% Differences against replicate, in the 3-pixel border and in the interior.
border = true(size(I)); border(4:end - 3, 4:end - 3) = false;
for k = [1 3 4]
    d = abs(modes{k} - I_rep);
    fprintf('%-16s vs replicate: max diff in border %.3f, in interior %.2g\n', ...
        modeNames{k}, max(d(border)), max(d(~border)));
end
fprintf('Mean of first/last image rows: top %.3f, bottom %.3f\n', mean(I(1, :)), mean(I(end, :)));

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

%% 7) Reflections
% 1) Why is Gaussian preferred over large box LP?
% 2) What does separability do for computational cost?
% 3) How do boundary modes change corners/edges?
% The answers are in README.md.
