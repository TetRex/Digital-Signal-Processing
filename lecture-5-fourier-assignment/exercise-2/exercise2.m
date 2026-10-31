% =========================================================================
% Digital Signal Processing - Lecture 5: Fourier Series, DTFT and DFT
% File: exercise2.m
% Exercise 2: Find Two Frequencies with the FFT
%   - Task 2: Plot the signal in the time domain
%   - Task 3: Calculate and plot the single-sided amplitude spectrum
%   - Task 4: Identify the two peaks and compare with the true values
%   - Task 5: Calculate the frequency-bin spacing
% Output: two-frequency-time.png, two-frequency-spectrum.png
% =========================================================================

clear; close all; clc;

outDir = fileparts(mfilename('fullpath'));
if isempty(outDir)
    outDir = pwd;
end

%% Common Parameters
fs = 200;               % sampling frequency (Hz)
T  = 1;                 % recording length (s)
t  = 0:1/fs:T-1/fs;     % 200 samples

f1 = 15;  A1 = 0.8;
f2 = 40;  A2 = 0.4;
x = A1*sin(2*pi*f1*t) + A2*sin(2*pi*f2*t);

blue   = [0      0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];

%% =========================================================================
% Task 2: Plot the signal in the time domain
% =========================================================================
fprintf('Running Task 2: Time-domain plot...\n');

fig1 = figure('Name', 'Exercise 2: Time Domain', 'NumberTitle', 'off', 'Color', 'w');
plot(t, x, '.-', 'Color', blue, 'LineWidth', 1, 'MarkerSize', 8);
title('x(t) = 0.8 sin(2\pi 15 t) + 0.4 sin(2\pi 40 t),  f_s = 200 Hz');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;
xlim([0, T]);
ylim([-1.5, 1.5]);

saveas(fig1, fullfile(outDir, 'two-frequency-time.png'));

%% =========================================================================
% Task 3: Single-sided amplitude spectrum
% =========================================================================
fprintf('Running Task 3: Single-sided amplitude spectrum...\n');

N = length(x);
Y = fft(x);

P2 = abs(Y/N);
P1 = P2(1:N/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = fs*(0:N/2)/N;

fig2 = figure('Name', 'Exercise 2: Spectrum', 'NumberTitle', 'off', 'Color', 'w');
stem(f, P1, 'filled', 'Color', blue, 'MarkerSize', 3);
title('Single-sided amplitude spectrum (N = 200, \Deltaf = 1 Hz)');
xlabel('Frequency (Hz)'); ylabel('Amplitude');
grid on;
xlim([0, fs/2]);
ylim([0, 1]);

%% =========================================================================
% Task 4: Identify the two peaks
% =========================================================================
fprintf('Running Task 4: Identifying peaks...\n');

[~, order] = sort(P1, 'descend');
peakIdx = sort(order(1:2));          % two largest bins, in frequency order

hold on;
plot(f(peakIdx), P1(peakIdx), 'o', 'Color', orange, 'MarkerSize', 10, 'LineWidth', 1.5);
for i = 1:2
    text(f(peakIdx(i)) + 2, P1(peakIdx(i)) + 0.04, ...
        sprintf('%.0f Hz, %.3f', f(peakIdx(i)), P1(peakIdx(i))), 'Color', orange);
end
hold off;

saveas(fig2, fullfile(outDir, 'two-frequency-spectrum.png'));

expectedF = [f1 f2];
expectedA = [A1 A2];
fprintf('\n  Peak | Expected f | Measured f | Expected A | Measured A\n');
for i = 1:2
    fprintf('   %d   |  %5.1f Hz  |  %5.1f Hz  |   %.3f    |   %.3f\n', ...
        i, expectedF(i), f(peakIdx(i)), expectedA(i), P1(peakIdx(i)));
end

%% =========================================================================
% Task 5: Frequency-bin spacing
% =========================================================================
df = fs / N;
fprintf('\nRunning Task 5: Bin spacing = fs/N = %d/%d = %.2f Hz\n', fs, N, df);
fprintf('Saved two-frequency-time.png and two-frequency-spectrum.png\n');
