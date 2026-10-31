% =========================================================================
% Digital Signal Processing - Lecture 5: Fourier Series, DTFT and DFT
% File: exercise3.m
% Exercise 3: Investigate Spectral Leakage
%   - Task 2: Spectrum of a one-second recording
%   - Task 3: Same signal, four-second recording
%   - Task 5: Zero-padding the one-second recording, fft(x, 4*length(x))
% Output: leakage-comparison.png (all three spectra, saved next to this script)
%
% The spectrum code follows the Exercise 2 pattern. Amplitudes are always
% divided by the number of real samples, not by the FFT length, so that
% zero-padding does not shrink them.
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

% Dashed lines at the true tone frequencies and amplitudes (one line object)
toneF = [f1 f1 NaN f2 f2];
toneA = [0  A1 NaN 0  A2];

%% =========================================================================
% Task 2: One-second recording
% =========================================================================
fprintf('Running Task 2: One-second recording...\n');
t1 = 0:1/fs:1-1/fs;                       % N = 200
x1 = makeSignal(t1);

N1 = length(x1);
Y  = fft(x1);
P2 = abs(Y/N1);
PA = P2(1:N1/2+1);
PA(2:end-1) = 2*PA(2:end-1);
fA = fs*(0:N1/2)/N1;

%% =========================================================================
% Task 3: Four-second recording (same fs and frequencies)
% =========================================================================
fprintf('Running Task 3: Four-second recording...\n');
t4 = 0:1/fs:4-1/fs;                       % N = 800
x4 = makeSignal(t4);

N4 = length(x4);
Y  = fft(x4);
P2 = abs(Y/N4);
PB = P2(1:N4/2+1);
PB(2:end-1) = 2*PB(2:end-1);
fB = fs*(0:N4/2)/N4;

%% =========================================================================
% Task 5: Zero-pad the one-second recording to 4*N points
% =========================================================================
fprintf('Running Task 5: Zero-padded one-second recording...\n');
Nfft = 4*N1;                              % 800 points: 200 samples + 600 zeros
Y  = fft(x1, Nfft);
P2 = abs(Y/N1);                           % divide by the 200 real samples
PC = P2(1:Nfft/2+1);
PC(2:end-1) = 2*PC(2:end-1);
fC = fs*(0:Nfft/2)/Nfft;

%% =========================================================================
% Task 4: Compare the spectra
% =========================================================================
fig = figure('Name', 'Exercise 3: Spectral Leakage', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 900 900]);

fRange = [8, 22];       % frequency range around the two tones

subplot(3, 1, 1);
stem(fA, PA, 'filled', 'Color', blue, 'MarkerSize', 4); hold on;
plot(toneF, toneA, '--', 'Color', gray, 'LineWidth', 1); hold off;
title(sprintf('1 s recording: N = %d, \\Deltaf = %.2f Hz', N1, fs/N1));
xlabel('Frequency (Hz)'); ylabel('Amplitude');
grid on; xlim(fRange); ylim([0, 1]);

subplot(3, 1, 2);
stem(fB, PB, 'filled', 'Color', orange, 'MarkerSize', 4); hold on;
plot(toneF, toneA, '--', 'Color', gray, 'LineWidth', 1); hold off;
title(sprintf('4 s recording: N = %d, \\Deltaf = %.2f Hz', N4, fs/N4));
xlabel('Frequency (Hz)'); ylabel('Amplitude');
grid on; xlim(fRange); ylim([0, 1]);

subplot(3, 1, 3);
plot(fC, PC, '.-', 'Color', yellow, 'LineWidth', 1.2, 'MarkerSize', 10); hold on;
stem(fA, PA, 'Color', blue, 'MarkerSize', 4);        % original 1 s bins on top
plot(toneF, toneA, '--', 'Color', gray, 'LineWidth', 1); hold off;
title(sprintf('1 s recording zero-padded to %d points: bins every %.2f Hz', ...
    Nfft, fs/Nfft));
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

