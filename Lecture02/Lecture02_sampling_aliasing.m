% =========================================================================
% Digital Signal Processing - Lecture 02: Sampling & Aliasing
% File: Lecture02_sampling_aliasing.m
% Description: MATLAB implementation for Lecture 02 tasks:
%   - Task 1: Create the Original Signal (10 Hz sine wave, duration 1s)
%   - Task 2: Investigate Different Sampling Frequencies (15, 20, 25, 50, 100 Hz)
%   - Task 3: Nyquist Analysis and Theoretical Computations
% =========================================================================

clear;
close all;
clc;

%% Common Parameters
fs_cont = 1000;                 % High sampling frequency to emulate continuous time (1000 Hz)
duration = 1.0;                 % Signal duration in seconds
dt = 1 / fs_cont;               % Time step for continuous representation (0.001 s)
t_cont = 0:dt:duration;         % Continuous time vector from 0 to 1 s

% Ensure figures directory exists for saved plots
figuresDir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end

%% =========================================================================
% Task 1: Create the Original Signal (15 points)
% Requirements:
%   - Generate a 10 Hz sine wave
%   - Duration: 1 second
%   - Sufficiently small time step to represent a continuous-time signal
%   - Plot with appropriate title, axis labels, grid, and legend
% =========================================================================
fprintf('Running Task 1: Create the Original Signal...\n');

% Signal specifications
f_orig = 10;                    % Frequency in Hz
A_orig = 1.0;                   % Amplitude
x_cont = A_orig * sin(2 * pi * f_orig * t_cont);

% Plot the continuous-time signal
fig1 = figure('Name', 'Task 1: Original Continuous-Time Signal', 'NumberTitle', 'off', 'Color', 'w');
plot(t_cont, x_cont, 'LineWidth', 2, 'Color', [0, 0.4470, 0.7410]);
title('Task 1: Original Continuous-Time Signal (10 Hz Sine Wave)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (s)', 'FontSize', 11);
ylabel('Amplitude', 'FontSize', 11);
grid on;
xlim([0, duration]);
ylim([-1.3, 1.3]);
legend(sprintf('Original Signal (f = %d Hz)', f_orig), 'Location', 'northeast', 'FontSize', 10);

% Save figure
saveas(fig1, fullfile(figuresDir, 'task1_original_signal.png'));
fprintf('Task 1 completed successfully! Plot saved to: %s\n', fullfile(figuresDir, 'task1_original_signal.png'));

%% =========================================================================
% Task 2: Investigate Different Sampling Frequencies (35 points)
% Requirements:
%   - Sample the 10 Hz signal at: 15 Hz, 20 Hz, 25 Hz, 50 Hz, 100 Hz
%   - For each sampling frequency:
%       * Plot original continuous signal
%       * Overlay sampled points using markers/stems
%       * Compare sampled representation with original signal
%   - Create one figure with five subplots
% =========================================================================
fprintf('\nRunning Task 2: Investigate Different Sampling Frequencies...\n');

sampling_rates = [15, 20, 25, 50, 100];
num_rates = length(sampling_rates);

descriptions = {
    'f_s = 15 Hz (f_s < 2f: Undersampled / Aliased to 5 Hz)', ...
    'f_s = 20 Hz (f_s = 2f: Nyquist Rate / Critical Sampling)', ...
    'f_s = 25 Hz (f_s > 2f: Slightly Oversampled)', ...
    'f_s = 50 Hz (f_s = 5f: Adequately Oversampled)', ...
    'f_s = 100 Hz (f_s = 10f: Highly Oversampled / Faithful Representation)'
};

fig2 = figure('Name', 'Task 2: Investigating Different Sampling Frequencies', ...
              'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 50, 850, 950]);

for i = 1:num_rates
    fs_curr = sampling_rates(i);
    t_samp = 0:(1 / fs_curr):duration;
    x_samp = A_orig * sin(2 * pi * f_orig * t_samp);
    
    subplot(num_rates, 1, i);
    
    % Plot original continuous-time signal (reference)
    p_orig = plot(t_cont, x_cont, '-', 'Color', [0, 0.4470, 0.7410, 0.55], 'LineWidth', 1.5);
    hold on;
    
    % Overlay connecting line of sampled points (reconstructed trajectory)
    p_interp = plot(t_samp, x_samp, '--', 'Color', [0.8500, 0.3250, 0.0980, 0.8], 'LineWidth', 1.1);
    
    % Overlay discrete sampled points using stems
    h_stem = stem(t_samp, x_samp, 'filled', ...
                  'Color', [0.8500, 0.3250, 0.0980], ...
                  'LineWidth', 1.2, ...
                  'MarkerFaceColor', [0.8500, 0.3250, 0.0980], ...
                  'MarkerSize', 4.5);
    
    hold off;
    grid on;
    xlim([0, duration]);
    ylim([-1.35, 1.35]);
    
    title(descriptions{i}, 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Amplitude', 'FontSize', 9);
    
    if i == num_rates
        xlabel('Time (s)', 'FontSize', 10);
    end
    
    legend([p_orig, h_stem, p_interp], ...
           {'Original Continuous (10 Hz)', ...
            sprintf('Sampled Points (f_s = %d Hz)', fs_curr), ...
            'Sampled Path'}, ...
           'Location', 'northeast', 'FontSize', 7.5);
end

% Save figure
saveas(fig2, fullfile(figuresDir, 'task2_sampling_frequencies.png'));
fprintf('Task 2 completed successfully! Plot saved to: %s\n', fullfile(figuresDir, 'task2_sampling_frequencies.png'));

%% =========================================================================
% Task 3: Nyquist Analysis (15 points)
% Requirements:
%   - Determine minimum sampling frequency using Nyquist Sampling Theorem
%   - Show calculation
%   - Answer:
%       1. Which sampling frequencies satisfy the Nyquist criterion?
%       2. Is sampling exactly at the Nyquist rate recommended in practice?
% =========================================================================
fprintf('\n=======================================================\n');
fprintf('Running Task 3: Nyquist Analysis...\n');
fprintf('=======================================================\n');

f_max = f_orig; % Highest frequency component = 10 Hz
f_nyquist = 2 * f_max;

fprintf('Signal Maximum Frequency: f_max = %d Hz\n', f_max);
fprintf('Nyquist Minimum Sampling Rate: f_s,min = 2 * f_max = 2 * %d = %d Hz\n\n', f_max, f_nyquist);

fprintf('Evaluation of tested frequencies against Nyquist criterion (f_s > 20 Hz):\n');
for i = 1:num_rates
    fs_curr = sampling_rates(i);
    if fs_curr > f_nyquist
        status = 'SATISFIES criterion (f_s > 2*f_max)';
    elseif fs_curr == f_nyquist
        status = 'CRITICAL LIMIT (f_s = 2*f_max, phase sensitive)';
    else
        status = 'VIOLATES criterion (f_s < 2*f_max, ALIASING)';
    end
    fprintf('  - %3d Hz: %s\n', fs_curr, status);
end

fprintf('\nPractical Recommendation:\n');
fprintf('  Sampling strictly at the Nyquist rate (20 Hz) is NOT recommended in practice.\n');
fprintf('  It leads to phase dependency (e.g. zero samples at phi=0) and requires\n');
fprintf('  physically impossible ideal brick-wall filters. Real-world systems use oversampling.\n');
fprintf('=======================================================\n');

fprintf('\nAll tasks executed successfully! Plots saved in: %s\n', figuresDir);
