% =========================================================================
% Digital Signal Processing - Lecture 5: Fourier Series, DTFT and DFT
% File: exercise4.m
% Exercise 4: Compare the DTFT and DFT
%   - Task 1: DTFT of x = [1 1 1 1] at 1000 frequencies in [-pi, pi]
%   - Task 2: DFT with fft(x,4) and fft(x,64)
%   - Task 3: Plot the magnitude of each result
% Output: dtft-dft-comparison.png (saved next to this script)
% =========================================================================

clear; close all; clc;

outDir = fileparts(mfilename('fullpath'));
if isempty(outDir)
    outDir = pwd;
end

%% Common Parameters
x = [1 1 1 1];
n = 0:length(x)-1;

blue   = [0      0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];
purple = [0.4940 0.1840 0.5560];

%% =========================================================================
% Task 1: DTFT at 1000 frequency values between -pi and pi
%   X(e^jw) = sum over n of x[n] e^(-jwn)
% =========================================================================
fprintf('Running Task 1: DTFT...\n');

w = linspace(-pi, pi, 1000);
X = x * exp(-1j * (n.' * w));

%% =========================================================================
% Task 2: DFT with 4 and 64 points
% =========================================================================
fprintf('Running Task 2: fft(x,4) and fft(x,64)...\n');

X4  = fft(x, 4);
X64 = fft(x, 64);

% Bin k sits at w_k = 2*pi*k/N. Move bins above pi to the range [-pi, pi).
w4  = binFrequencies(4);
w64 = binFrequencies(64);

fprintf('  |fft(x,4)| = [%s]\n', sprintf('%.2f ', abs(X4)));
fprintf('  fft(x,64) bins with |X| < 1e-10: k = %s\n', mat2str(find(abs(X64) < 1e-10) - 1));

%% =========================================================================
% Task 3: Plot the magnitude of each result
% =========================================================================
fprintf('Running Task 3: Plotting...\n');

fig = figure('Name', 'Exercise 4: DTFT vs DFT', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 900 900]);
ticks = -pi:pi/2:pi;
tickLabels = {'-\pi', '-\pi/2', '0', '\pi/2', '\pi'};

subplot(3, 1, 1);
plot(w, abs(X), 'Color', blue, 'LineWidth', 1.5);
title('DTFT |X(e^{j\omega})| of x = [1 1 1 1]  (1000 points)');
xlabel('Angular frequency (rad/sample)'); ylabel('Magnitude');
grid on; xlim([-pi, pi]); ylim([0, 4.5]);
set(gca, 'XTick', ticks, 'XTickLabel', tickLabels);

subplot(3, 1, 2);
plot(w, abs(X), 'Color', blue, 'LineWidth', 1); hold on;
stem(w4, abs(X4), 'filled', 'Color', orange, 'LineWidth', 1.5, 'MarkerSize', 7);
hold off;
title('|fft(x,4)|: 4 samples of the DTFT, spaced 2\pi/4');
xlabel('Angular frequency (rad/sample)'); ylabel('Magnitude');
legend('DTFT', 'fft(x,4)', 'Location', 'northeast');
grid on; xlim([-pi, pi]); ylim([0, 4.5]);
set(gca, 'XTick', ticks, 'XTickLabel', tickLabels);

subplot(3, 1, 3);
plot(w, abs(X), 'Color', blue, 'LineWidth', 1); hold on;
stem(w64, abs(X64), 'filled', 'Color', purple, 'MarkerSize', 3);
hold off;
title('|fft(x,64)|: 64 samples of the same DTFT, spaced 2\pi/64');
xlabel('Angular frequency (rad/sample)'); ylabel('Magnitude');
legend('DTFT', 'fft(x,64)', 'Location', 'northeast');
grid on; xlim([-pi, pi]); ylim([0, 4.5]);
set(gca, 'XTick', ticks, 'XTickLabel', tickLabels);

saveas(fig, fullfile(outDir, 'dtft-dft-comparison.png'));
fprintf('Saved dtft-dft-comparison.png\n');

%% =========================================================================
% Local functions
% =========================================================================
function wk = binFrequencies(N)
% Angular frequency of each DFT bin, mapped from [0, 2*pi) to [-pi, pi)
    wk = 2*pi*(0:N-1)/N;
    wk(wk >= pi) = wk(wk >= pi) - 2*pi;
end
