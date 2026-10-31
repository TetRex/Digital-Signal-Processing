% =========================================================================
% Digital Signal Processing - Z-transform and Sample Delays
% File: Z_transform_sample_delays.m
% Description: MATLAB implementation for the Z-transform assignment:
%   - Part 1: A signal x[n] = {1, 2, 1} and its one-sample delay x[n-1]
%   - Part 2: The system y[n] = 0.5x[n] + 0.5x[n-1], H(z) = 0.5 + 0.5z^-1
%   - Task 6: The modified system H(z) = 0.8 + 0.2z^-1
% No Symbolic Math Toolbox is required.
% =========================================================================

clear; clc; close all;

% Ensure figures directory exists for saved plots
figuresDir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end

%% =========================================================================
% Part 1: A signal and its Z-transform
%   x[0] = 1, x[1] = 2, x[2] = 1  ->  X(z) = 1 + 2z^-1 + z^-2
% =========================================================================
fprintf('Running Part 1: Signal and its one-sample delay...\n');

x = [1 2 1];
n = 0:length(x)-1;

% Delay the signal by one sample
xDelayed = [0 x];
nDelayed = 0:length(xDelayed)-1;

fig1 = figure('Name', 'Part 1: Original and Delayed Signal', 'NumberTitle', 'off', 'Color', 'w');
subplot(2,1,1);
stem(n, x, 'filled');
title('Original Signal x[n]');
xlabel('Sample n'); ylabel('Amplitude');
grid on;
xlim([-0.5, 3.5]);
ylim([0, 2.5]);

subplot(2,1,2);
stem(nDelayed, xDelayed, 'filled');
title('One-Sample Delay x[n-1]');
xlabel('Sample n'); ylabel('Amplitude');
grid on;
xlim([-0.5, 3.5]);
ylim([0, 2.5]);

%% =========================================================================
% Part 2: A system with one sample delay
%   y[n] = 0.5x[n] + 0.5x[n-1]  ->  H(z) = 0.5 + 0.5z^-1
% =========================================================================
fprintf('Running Part 2: System H(z) = 0.5 + 0.5z^-1...\n');

% Coefficients of H(z) = 0.5 + 0.5*z^(-1)
b = [0.5 0.5];
a = 1;

% Add one zero to show the final output sample
xInput = [x 0];
y = filter(b, a, xInput);
nOutput = 0:length(y)-1;

fig2 = figure('Name', 'Part 2: Input and Output, H(z) = 0.5 + 0.5z^-1', 'NumberTitle', 'off', 'Color', 'w');
subplot(2,1,1);
stem(nOutput, xInput, 'filled');
title('Input x[n]');
xlabel('Sample n'); ylabel('Amplitude');
grid on;
xlim([-0.5, 3.5]);
ylim([0, 2.5]);

subplot(2,1,2);
stem(nOutput, y, 'filled');
title('Output y[n], H(z) = 0.5 + 0.5z^{-1}');
xlabel('Sample n'); ylabel('Amplitude');
grid on;
xlim([-0.5, 3.5]);
ylim([0, 2.5]);

disp('Output samples:');
disp(y);

% Task 4: Compare hand calculation with MATLAB
yHand = [0.5 1.5 1.5 0.5];
fprintf('Hand-calculated y[n]: %s\n', mat2str(yHand));
fprintf('MATLAB filter  y[n]: %s\n', mat2str(y));
fprintf('Max absolute difference: %g\n\n', max(abs(y - yHand)));

%% =========================================================================
% Task 6: Modified system
%   H(z) = 0.8 + 0.2z^-1  ->  y[n] = 0.8x[n] + 0.2x[n-1]
% =========================================================================
fprintf('Running Task 6: System H(z) = 0.8 + 0.2z^-1...\n');

b2 = [0.8 0.2];
y2 = filter(b2, a, xInput);

fig3 = figure('Name', 'Task 6: Input and Output, H(z) = 0.8 + 0.2z^-1', 'NumberTitle', 'off', 'Color', 'w');
subplot(2,1,1);
stem(nOutput, xInput, 'filled');
title('Input x[n]');
xlabel('Sample n'); ylabel('Amplitude');
grid on;
xlim([-0.5, 3.5]);
ylim([0, 2.5]);

subplot(2,1,2);
stem(nOutput, y2, 'filled');
title('Output y[n], H(z) = 0.8 + 0.2z^{-1}');
xlabel('Sample n'); ylabel('Amplitude');
grid on;
xlim([-0.5, 3.5]);
ylim([0, 2.5]);

disp('Output samples (b = [0.8 0.2]):');
disp(y2);

fprintf('All tasks completed successfully! Plots saved in: %s\n', figuresDir);
