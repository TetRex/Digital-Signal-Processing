% =========================================================================
% Digital Signal Processing - Lecture 5: Fourier Series, DTFT and DFT
% File: exercise3.m
% Exercise 3: Investigate Spectral Leakage
%   - Task 2: Spectrum of a one-second recording
%   - Task 3: Same signal, four-second recording
%   - Task 5: Zero-padding the one-second recording, fft(x, 4*length(x))
% Output: leakage-comparison.png (all three spectra, saved next to this script)
% =========================================================================

clear; close all; clc;

outDir = fileparts(mfilename('fullpath'));
if isempty(outDir)
    outDir = pwd;
end

%% Common Parameters
fs = 200;                 % sampling frequency (Hz), same as Exercise 2
d  = 8;                   % last digit of student number
f1 = 15;   A1 = 0.8;
f2 = 13.2 + 0.17*d;       % = 14.56 Hz, not an integer number of cycles in 1 s
A2 = 0.4;

fprintf('d = %d, f2 = %.2f Hz\n', d, f2);

makeSignal = @(t) A1*sin(2*pi*f1*t) + A2*sin(2*pi*f2*t);

blue   = [0      0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];
yellow = [0.9290 0.6940 0.1250];
gray   = [0.5 0.5 0.5];

%% =========================================================================
% Task 2: One-second recording
% =========================================================================
fprintf('Running Task 2: One-second recording...\n');
t1 = 0:1/fs:1-1/fs;                       % N = 200
x1 = makeSignal(t1);
[fA, PA] = singleSidedSpectrum(x1, fs, length(x1));

%% =========================================================================
% Task 3: Four-second recording (same fs and frequencies)
% =========================================================================
fprintf('Running Task 3: Four-second recording...\n');
t4 = 0:1/fs:4-1/fs;                       % N = 800
x4 = makeSignal(t4);
[fB, PB] = singleSidedSpectrum(x4, fs, length(x4));

%% =========================================================================
% Task 5: Zero-pad the one-second recording to 4*N points
% =========================================================================
fprintf('Running Task 5: Zero-padded one-second recording...\n');
[fC, PC] = singleSidedSpectrum(x1, fs, 4*length(x1));

%% =========================================================================
% Task 4: Compare the spectra
% =========================================================================
fig = figure('Name', 'Exercise 3: Spectral Leakage', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 900 900]);

fRange = [8, 22];       % frequency range around the two tones

subplot(3, 1, 1);
stem(fA, PA, 'filled', 'Color', blue, 'MarkerSize', 4); hold on;
markTrueTones(f1, A1, f2, A2, gray); hold off;
title(sprintf('1 s recording: N = %d, \\Deltaf = %.2f Hz', length(x1), fs/length(x1)));
xlabel('Frequency (Hz)'); ylabel('Amplitude');
grid on; xlim(fRange); ylim([0, 1]);

subplot(3, 1, 2);
stem(fB, PB, 'filled', 'Color', orange, 'MarkerSize', 4); hold on;
markTrueTones(f1, A1, f2, A2, gray); hold off;
title(sprintf('4 s recording: N = %d, \\Deltaf = %.2f Hz', length(x4), fs/length(x4)));
xlabel('Frequency (Hz)'); ylabel('Amplitude');
grid on; xlim(fRange); ylim([0, 1]);

subplot(3, 1, 3);
plot(fC, PC, '.-', 'Color', yellow, 'LineWidth', 1.2, 'MarkerSize', 10); hold on;
stem(fA, PA, 'Color', blue, 'MarkerSize', 4);        % original 1 s bins on top
markTrueTones(f1, A1, f2, A2, gray); hold off;
title(sprintf('1 s recording zero-padded to %d points: bins every %.2f Hz', ...
    4*length(x1), fs/(4*length(x1))));
xlabel('Frequency (Hz)'); ylabel('Amplitude');
legend('Zero-padded FFT', 'Original 1 s bins', 'True tones', 'Location', 'northeast');
grid on; xlim(fRange); ylim([0, 1]);

saveas(fig, fullfile(outDir, 'leakage-comparison.png'));

% Print the bins around the two tones for the README
cases  = {'1 s', fA, PA; '4 s', fB, PB; 'zero-padded', fC, PC};
for i = 1:size(cases, 1)
    f = cases{i, 2}; P = cases{i, 3};
    band = f >= 13.5 & f <= 16;
    fprintf('\n  %s:\n', cases{i, 1});
    fprintf('    %6.2f Hz  %.4f\n', [f(band); P(band)]);
end
fprintf('\nSaved leakage-comparison.png\n');

%% =========================================================================
% Local functions
% =========================================================================
function [f, P1] = singleSidedSpectrum(x, fs, nfft)
% Single-sided amplitude spectrum, as in Exercise 2. Divide by the number of
% real samples, not nfft, so zero-padding does not shrink the amplitudes.
    Y  = fft(x, nfft);
    P2 = abs(Y / length(x));
    P1 = P2(1:nfft/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f  = fs*(0:nfft/2)/nfft;
end

function markTrueTones(f1, A1, f2, A2, color)
% Dashed lines at the true frequencies and amplitudes
    plot([f1 f1], [0 A1], '--', 'Color', color, 'LineWidth', 1);
    plot([f2 f2], [0 A2], '--', 'Color', color, 'LineWidth', 1);
end
