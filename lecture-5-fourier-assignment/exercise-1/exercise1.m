% =========================================================================
% Digital Signal Processing - Lecture 5: Fourier Series, DTFT and DFT
% File: exercise1.m
% Exercise 1: Build a Square Wave from Harmonics
%   - Task 2: Build a square wave from odd harmonics for H = 1, 3, 9, 25
%   - Task 3: Plot the four results so they can be compared
%   - Task 5: Zoom in on a sharp transition (Gibbs phenomenon)
% Output: square-wave-comparison.png (saved next to this script)
% =========================================================================

clear; close all; clc;

outDir = fileparts(mfilename('fullpath'));
if isempty(outDir)
    outDir = pwd;
end

%% Common Parameters
t = linspace(-1, 1, 4000);          % 2 s of a 1 Hz square wave
Hvalues = [1 3 9 25];               % highest odd harmonic used
idealSquare = sign(sin(2*pi*t));    % ideal square wave, for reference

colors = [0      0.4470 0.7410;
          0.8500 0.3250 0.0980;
          0.9290 0.6940 0.1250;
          0.4940 0.1840 0.5560];
gray = [0.5 0.5 0.5];

%% =========================================================================
% Task 2: Build the approximations
%   x(t) = (4/pi) * sum over odd k <= H of sin(2*pi*k*t) / k
% =========================================================================
fprintf('Running Task 2: Building square wave approximations...\n');

approx = zeros(length(Hvalues), length(t));
for i = 1:length(Hvalues)
    H = Hvalues(i);
    x = zeros(size(t));
    for k = 1:2:H
        x = x + (4/pi) * sin(2*pi*k*t) / k;
    end
    approx(i, :) = x;

    fprintf('  H = %2d: %2d harmonics, peak value = %.4f (overshoot %.1f%%)\n', ...
        H, (H+1)/2, max(x), (max(x) - 1) * 100);
end

%% =========================================================================
% Task 3: Plot the four results so they can be compared
% Task 5: Look closely near the sharp transitions
% =========================================================================
fprintf('Running Task 3: Plotting the comparison...\n');

fig = figure('Name', 'Exercise 1: Square Wave from Harmonics', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [100 100 1000 900]);

for i = 1:length(Hvalues)
    subplot(3, 2, i);
    plot(t, idealSquare, '--', 'Color', gray, 'LineWidth', 1); hold on;
    plot(t, approx(i, :), 'Color', colors(i, :), 'LineWidth', 1.3);
    hold off;
    nTerms = (Hvalues(i)+1)/2;
    if nTerms == 1
        title(sprintf('H = %d (1 term: the fundamental only)', Hvalues(i)));
    else
        title(sprintf('H = %d (%d odd harmonics)', Hvalues(i), nTerms));
    end
    xlabel('Time (s)'); ylabel('Amplitude');
    grid on;
    xlim([-1, 1]);
    ylim([-1.5, 1.5]);
end

% Zoom on the jump at t = 0 with all four approximations overlaid
subplot(3, 2, [5 6]);
plot(t, idealSquare, '--', 'Color', gray, 'LineWidth', 1); hold on;
for i = 1:length(Hvalues)
    plot(t, approx(i, :), 'Color', colors(i, :), 'LineWidth', 1.3);
end
plot([-1 1], [1.179 1.179], ':', 'Color', 'k', 'LineWidth', 1);   % Gibbs limit, about 9% of the jump
hold off;
title('Zoom near the jump at t = 0 (Gibbs phenomenon)');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Ideal square wave', 'H = 1', 'H = 3', 'H = 9', 'H = 25', ...
    'Gibbs limit \approx 1.18', 'Location', 'eastoutside');
grid on;
xlim([-0.1, 0.25]);
ylim([-1.5, 1.5]);

saveas(fig, fullfile(outDir, 'square-wave-comparison.png'));
fprintf('Saved square-wave-comparison.png\n');
