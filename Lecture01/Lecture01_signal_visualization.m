% =========================================================================
% Digital Signal Processing - Lecture 01: Signal Visualization
% File: Lecture01_signal_visualization.m
% Description: MATLAB implementation for Lecture 01 tasks:
%   - Task 1: Generate and plot a 5 Hz sine wave
%   - Task 2: Compare sine waves with different frequencies (2 Hz, 5 Hz, 10 Hz)
%   - Task 3: Compare sine waves with different amplitudes (0.5, 1, 2)
%   - Task 4: Add random noise to a clean sine wave
% =========================================================================

clear;
close all;
clc;

%% Common Parameters
fs = 1000;              % Sampling frequency in Hz (1000 samples/second)
duration = 1.0;         % Duration in seconds
t = 0:(1/fs):duration;  % Time vector from 0 to 1 second

% Ensure figures directory exists for saved plots
figuresDir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end

%% =========================================================================
% Task 1: Create a Sine Wave
% Requirements:
%   - Amplitude = 1
%   - Frequency = 5 Hz
%   - Duration = 1 second
%   - Plot with: Title, X-axis label, Y-axis label, Grid enabled
% =========================================================================
fprintf('Running Task 1: Create a Sine Wave...\n');

A1 = 1;     % Amplitude
f1 = 5;     % Frequency in Hz
y1 = A1 * sin(2 * pi * f1 * t);

fig1 = figure('Name', 'Task 1: Sine Wave', 'NumberTitle', 'off', 'Color', 'w');
plot(t, y1, 'LineWidth', 2, 'Color', [0, 0.4470, 0.7410]);
title('Task 1: 5 Hz Sine Wave (Amplitude = 1, Duration = 1 s)', 'FontSize', 12);
xlabel('Time (s)', 'FontSize', 11);
ylabel('Amplitude', 'FontSize', 11);
grid on;
xlim([0, duration]);
ylim([-1.3, 1.3]);

% Save figure
saveas(fig1, fullfile(figuresDir, 'task1_sine_wave.png'));

%% =========================================================================
% Task 2: Compare Different Frequencies
% Requirements:
%   - Generate three sine waves: 2 Hz, 5 Hz, 10 Hz
%   - Display them using subplots
% =========================================================================
fprintf('Running Task 2: Compare Different Frequencies...\n');

f_2Hz  = 2;   % 2 Hz frequency
f_5Hz  = 5;   % 5 Hz frequency
f_10Hz = 10;  % 10 Hz frequency

y_2Hz  = sin(2 * pi * f_2Hz * t);
y_5Hz  = sin(2 * pi * f_5Hz * t);
y_10Hz = sin(2 * pi * f_10Hz * t);

fig2 = figure('Name', 'Task 2: Frequency Comparison', 'NumberTitle', 'off', 'Color', 'w');

% Subplot 1: 2 Hz
subplot(3, 1, 1);
plot(t, y_2Hz, 'LineWidth', 1.8, 'Color', [0.8500, 0.3250, 0.0980]);
title('Sine Wave - 2 Hz (2 cycles in 1 second)', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 10);
ylabel('Amplitude', 'FontSize', 10);
grid on;
xlim([0, duration]);
ylim([-1.3, 1.3]);

% Subplot 2: 5 Hz
subplot(3, 1, 2);
plot(t, y_5Hz, 'LineWidth', 1.8, 'Color', [0, 0.4470, 0.7410]);
title('Sine Wave - 5 Hz (5 cycles in 1 second)', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 10);
ylabel('Amplitude', 'FontSize', 10);
grid on;
xlim([0, duration]);
ylim([-1.3, 1.3]);

% Subplot 3: 10 Hz
subplot(3, 1, 3);
plot(t, y_10Hz, 'LineWidth', 1.8, 'Color', [0.4660, 0.6740, 0.1880]);
title('Sine Wave - 10 Hz (10 cycles in 1 second)', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 10);
ylabel('Amplitude', 'FontSize', 10);
grid on;
xlim([0, duration]);
ylim([-1.3, 1.3]);

% Save figure
saveas(fig2, fullfile(figuresDir, 'task2_frequency_comparison.png'));

%% =========================================================================
% Task 3: Compare Different Amplitudes
% Requirements:
%   - Generate three sine waves with amplitudes: 0.5, 1, 2
%   - Use the same frequency for all signals (5 Hz)
%   - Display them using subplots
% =========================================================================
fprintf('Running Task 3: Compare Different Amplitudes...\n');

amp1 = 0.5;
amp2 = 1.0;
amp3 = 2.0;
f_common = 5;  % 5 Hz for all signals

y_amp05 = amp1 * sin(2 * pi * f_common * t);
y_amp10 = amp2 * sin(2 * pi * f_common * t);
y_amp20 = amp3 * sin(2 * pi * f_common * t);

fig3 = figure('Name', 'Task 3: Amplitude Comparison', 'NumberTitle', 'off', 'Color', 'w');

% Subplot 1: Amplitude = 0.5
subplot(3, 1, 1);
plot(t, y_amp05, 'LineWidth', 1.8, 'Color', [0.4940, 0.1840, 0.5560]);
title('Sine Wave - Amplitude = 0.5 (f = 5 Hz)', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 10);
ylabel('Amplitude', 'FontSize', 10);
grid on;
xlim([0, duration]);
ylim([-2.5, 2.5]);

% Subplot 2: Amplitude = 1.0
subplot(3, 1, 2);
plot(t, y_amp10, 'LineWidth', 1.8, 'Color', [0, 0.4470, 0.7410]);
title('Sine Wave - Amplitude = 1.0 (f = 5 Hz)', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 10);
ylabel('Amplitude', 'FontSize', 10);
grid on;
xlim([0, duration]);
ylim([-2.5, 2.5]);

% Subplot 3: Amplitude = 2.0
subplot(3, 1, 3);
plot(t, y_amp20, 'LineWidth', 1.8, 'Color', [0.6350, 0.0780, 0.1840]);
title('Sine Wave - Amplitude = 2.0 (f = 5 Hz)', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 10);
ylabel('Amplitude', 'FontSize', 10);
grid on;
xlim([0, duration]);
ylim([-2.5, 2.5]);

% Save figure
saveas(fig3, fullfile(figuresDir, 'task3_amplitude_comparison.png'));

%% =========================================================================
% Task 4: Add Noise
% Requirements:
%   - Generate a clean sine wave
%   - Add random noise to create a noisy signal
%   - Display clean signal and noisy signal using subplots
% =========================================================================
fprintf('Running Task 4: Add Noise...\n');

% Set random seed for consistent reproducibility
rng(42);

% Clean signal (5 Hz, Amplitude = 1)
y_clean = 1.0 * sin(2 * pi * 5 * t);

% Generate Gaussian white noise (standard deviation = 0.35)
noise_amplitude = 0.35;
noise = noise_amplitude * randn(size(t));

% Noisy signal
y_noisy = y_clean + noise;

fig4 = figure('Name', 'Task 4: Clean vs. Noisy Signal', 'NumberTitle', 'off', 'Color', 'w');

% Subplot 1: Clean Signal
subplot(2, 1, 1);
plot(t, y_clean, 'LineWidth', 2, 'Color', [0, 0.4470, 0.7410]);
title('Clean Signal (5 Hz Sine Wave, Amplitude = 1)', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 10);
ylabel('Amplitude', 'FontSize', 10);
grid on;
xlim([0, duration]);
ylim([-2.2, 2.2]);

% Subplot 2: Noisy Signal
subplot(2, 1, 2);
plot(t, y_noisy, 'LineWidth', 1.2, 'Color', [0.8500, 0.3250, 0.0980]);
title('Noisy Signal (Clean Sine Wave + Gaussian White Noise)', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 10);
ylabel('Amplitude', 'FontSize', 10);
grid on;
xlim([0, duration]);
ylim([-2.2, 2.2]);

% Save figure
saveas(fig4, fullfile(figuresDir, 'task4_clean_vs_noisy.png'));

fprintf('All tasks completed successfully! Plots saved in: %s\n', figuresDir);
