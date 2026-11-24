% =========================================================================
% Digital Signal Processing - Lecture 9, Lab 3: Frequency-Domain
%   Filtering with fft2
% File: Lecture09_lab3_frequency_filtering.m
% Description: the lab script, unchanged in its computations, with
%   additions that support the screenshots and the reflections:
%   - every figure is saved to figures/*.png (all at once at the end;
%     a failed save only warns, and no local functions are used)
%   - Section 2: the two filter masks H(u,v) and their radial profiles
%   - Section 3: a zoom and a 1D profile across an edge to show ringing
%   - Section 5: the lab's two Gaussians use different widths, so a
%     frequency-domain Gaussian matched to sigma = 1.2 px is added
%   - Reflection 3: timing of spatial vs FFT filtering for growing kernels
% Requires: Image Processing Toolbox (fspecial, imfilter, montage,
%   mat2gray); fft2, ifft2, fftshift and timeit are base MATLAB.
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
[M, N] = size(I);
fprintf('Image: M = %d rows, N = %d columns\n', M, N);

%% 1) Magnitude spectrum (log-scale)
F = fft2(I);
Fshift = fftshift(F);
S = log(1 + abs(Fshift));
fig = figure('Position', [100 100 1200 460]); theme(fig, 'light');
subplot(1, 2, 1); imshow(I, []); title('Image');
subplot(1, 2, 2); imshow(S, []); title('Log-magnitude spectrum (centered)');
figList(end + 1, :) = {fig, 'fig1_spectrum.png'};

% Added: the same spectrum without fftshift, for the reflection on fftshift.
fig = figure('Position', [100 100 1200 460]); theme(fig, 'light');
subplot(1, 2, 1); imshow(log(1 + abs(F)), []); title('Without fftshift: DC in the corners');
subplot(1, 2, 2); imshow(S, []); title('With fftshift: DC in the centre');
figList(end + 1, :) = {fig, 'fig1_fftshift.png'};

fprintf('DC term F(1,1) = %.1f = M*N*mean(I) = %.1f\n', real(F(1, 1)), M * N * mean(I(:)));
energy = abs(Fshift).^2;

%% 2) Ideal & Gaussian Low-pass in frequency
[u, v] = meshgrid((-floor(N/2)):(ceil(N/2) - 1), (-floor(M/2)):(ceil(M/2) - 1));
D = sqrt(u.^2 + v.^2);
D0 = 40; % cutoff radius
H_ideal_LP = double(D <= D0); % ideal circular LP
sigma = 20;
H_gauss_LP = exp(-(D.^2) / (2 * sigma^2));

% Added: the masks and their profiles along the horizontal frequency axis.
fig = figure('Position', [100 100 1500 420]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(H_ideal_LP); title(sprintf('Ideal LP, D_0 = %d', D0));
nexttile; imshow(H_gauss_LP); title(sprintf('Gaussian LP, \\sigma = %d', sigma));
nexttile;
row0 = floor(M/2) + 1;   % the row where v = 0
plot(u(row0, :), H_ideal_LP(row0, :), 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5); hold on;
plot(u(row0, :), H_gauss_LP(row0, :), 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5); hold off;
grid on; xlim([-120 120]); ylim([-0.05 1.1]);
xlabel('u (frequency index)'); ylabel('H(u, 0)');
title('Profile through the centre'); legend('Ideal', 'Gaussian', 'Location', 'northeast');
figList(end + 1, :) = {fig, 'fig2_filters.png'};

fprintf('Energy kept (without DC): ideal LP %.2f %%, Gaussian LP %.2f %%\n', ...
    100 * (sum(energy(:) .* H_ideal_LP(:).^2) - energy(D == 0)) / (sum(energy(:)) - energy(D == 0)), ...
    100 * (sum(energy(:) .* H_gauss_LP(:).^2) - energy(D == 0)) / (sum(energy(:)) - energy(D == 0)));

%% 3) Apply LP filters in frequency domain
G_ideal = ifft2(ifftshift(H_ideal_LP .* Fshift));
G_gauss = ifft2(ifftshift(H_gauss_LP .* Fshift));
fig = figure('Position', [100 100 1500 420]); theme(fig, 'light');
montage({I, real(G_ideal), real(G_gauss)}, 'Size', [1 3]);
title('Original | Ideal LP | Gaussian LP (ringing vs smooth)');
figList(end + 1, :) = {fig, 'fig3_lowpass.png'};

fprintf('Largest imaginary part after ifft2: ideal %.2g, Gaussian %.2g (symmetric masks give a real result)\n', ...
    max(abs(imag(G_ideal(:)))), max(abs(imag(G_gauss(:)))));

% Added: zoom on the white garlic at the bottom right, and a profile
% along one row across its edges.
zr = 236:355; zc = 390:509;
profRow = 300;
fig = figure('Position', [100 100 1500 420]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(I(zr, zc)); title('Original, zoom');
hold on; plot([1 numel(zc)], (profRow - zr(1) + 1) * [1 1], 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 1); hold off;
nexttile; imshow(real(G_ideal(zr, zc)), [0 1]); title('Ideal LP, zoom: ripples');
nexttile; imshow(real(G_gauss(zr, zc)), [0 1]); title('Gaussian LP, zoom: smooth');
figList(end + 1, :) = {fig, 'fig3_zoom.png'};

fig = figure; theme(fig, 'light');
plot(zc, I(profRow, zc), 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
plot(zc, real(G_ideal(profRow, zc)), 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5);
plot(zc, real(G_gauss(profRow, zc)), 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5); hold off;
grid on; xlim([zc(1) zc(end)]); ylim([-0.1 1.1]);
xlabel('Column'); ylabel('Grey level');
title(sprintf('Row %d across the garlic (yellow line)', profRow));
legend('Original', 'Ideal LP', 'Gaussian LP', 'Location', 'southwest');
figList(end + 1, :) = {fig, 'fig3_profile.png'};

fprintf('Ideal LP output range [%.3f, %.3f]; Gaussian LP output range [%.3f, %.3f] (input [%.3f, %.3f])\n', ...
    min(real(G_ideal(:))), max(real(G_ideal(:))), min(real(G_gauss(:))), max(real(G_gauss(:))), min(I(:)), max(I(:)));

%% 4) High-pass via complement
H_gauss_HP = 1 - H_gauss_LP;
G_hp = real(ifft2(ifftshift(H_gauss_HP .* Fshift)));
G_hp = mat2gray(G_hp);
fig = figure('Position', [100 100 1100 420]); theme(fig, 'light');
montage({I, G_hp}, 'Size', [1 2]);
title('Original | Gaussian High-pass result');
figList(end + 1, :) = {fig, 'fig4_highpass.png'};

fprintf('High-pass removes the DC term: H_HP(0,0) = %g\n', H_gauss_HP(D == 0));

%% 5) Compare spatial vs frequency-domain Gaussian LP
g1d = fspecial('gaussian', [1 7], 1.2);
I_spatial_gauss = imfilter(I, g1d' * g1d, 'replicate');
fig = figure('Position', [100 100 1100 420]); theme(fig, 'light');
montage({I_spatial_gauss, real(G_gauss)}, 'Size', [1 2]);
title('Spatial Gaussian LP | Frequency-domain Gaussian LP');
figList(end + 1, :) = {fig, 'fig5_spatial_vs_frequency.png'};

% Added: a frequency-domain Gaussian with sigma = 20 frequency samples
% equals a spatial Gaussian with sigma_x = N/(2*pi*20) and
% sigma_y = M/(2*pi*20), not 1.2 px. The matched filter for sigma = 1.2 px
% is H = exp(-2*pi^2*1.2^2*((u/N)^2 + (v/M)^2)).
sigma_s = 1.2;
fprintf('Lab Gaussian (sigma = %d samples) equals a spatial sigma of %.2f px (x) and %.2f px (y)\n', ...
    sigma, N / (2 * pi * sigma), M / (2 * pi * sigma));
H_matched = exp(-2 * pi^2 * sigma_s^2 * ((u / N).^2 + (v / M).^2));
G_matched = real(ifft2(ifftshift(H_matched .* Fshift)));

inner = false(M, N); inner(11:end - 10, 11:end - 10) = true;   % away from the border
dLab = abs(I_spatial_gauss - real(G_gauss));
dMatched = abs(I_spatial_gauss - G_matched);
fprintf('Spatial vs lab frequency Gaussian:     max diff %.3f, mean diff %.4f (interior)\n', ...
    max(dLab(inner)), mean(dLab(inner)));
fprintf('Spatial vs matched frequency Gaussian: max diff %.4f, mean diff %.5f (interior); max diff at the border %.3f\n', ...
    max(dMatched(inner)), mean(dMatched(inner)), max(dMatched(~inner)));

fig = figure('Position', [100 100 1500 420]); theme(fig, 'light');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(I_spatial_gauss(zr, zc)); title('Spatial, \sigma = 1.2 px');
nexttile; imshow(real(G_gauss(zr, zc)), [0 1]); title('Frequency, lab \sigma = 20 samples');
nexttile; imshow(G_matched(zr, zc), [0 1]); title('Frequency, matched to \sigma = 1.2 px');
figList(end + 1, :) = {fig, 'fig5_matched_gaussian.png'};

%% Timing (added, for reflection 3)
% Spatial filtering costs about k^2 operations per pixel for a k x k
% kernel; FFT filtering costs about the same for any kernel size.
kSizes = [7 15 31 61 101];
tSpatial = zeros(size(kSizes));
tFft = zeros(size(kSizes));
timeit(@() real(ifft2(fft2(I))));          % warm-up: the first FFT calls are slower
for k = 1:numel(kSizes)
    h = fspecial('gaussian', kSizes(k), kSizes(k) / 6);
    Hk = fft2(h, M, N);                       % kernel spectrum, zero-padded
    tSpatial(k) = timeit(@() conv2(I, h, 'same'));
    tFft(k) = timeit(@() real(ifft2(fft2(I) .* Hk)));
end
disp(table(kSizes', round(1000 * tSpatial', 2), round(1000 * tFft', 2), ...
    'VariableNames', {'KernelSize', 'Spatial_conv2_ms', 'FFT_ms'}));

fig = figure; theme(fig, 'light');
loglog(kSizes, 1000 * tSpatial, '-o', 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5); hold on;
loglog(kSizes, 1000 * tFft, '-s', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5); hold off;
grid on; xlim([5 120]);
xlabel('Kernel size k (k x k)'); ylabel('Time (ms)');
title(sprintf('Filtering a %d x %d image: spatial vs FFT', M, N));
legend('Spatial conv2 (full 2D kernel)', 'FFT (fft2, multiply, ifft2)', 'Location', 'northwest');
figList(end + 1, :) = {fig, 'fig6_timing.png'};

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
% 1) Why does ideal LP cause ringing (Gibbs phenomenon)?
% 2) What does fftshift do visually?
% 3) When is frequency-domain filtering computationally preferable?
% The answers are in README.md.
