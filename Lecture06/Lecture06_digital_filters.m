% =========================================================================
% Digital Signal Processing - Lecture 6: Digital Filter Design
% File: Lecture06_digital_filters.m
% Description:
%   Part A: Filter a synthetic sensor signal (5 Hz + 12 Hz wanted,
%           50 Hz + 137 Hz interference + random noise) with a 20 Hz
%           low-pass FIR (order 60) and a 4th-order Butterworth IIR.
%   Part B: Remove an added 50 Hz hum from the Handel recording with a
%           narrow (49-51 Hz) and a wide (45-55 Hz) Butterworth band-stop.
% Requires: Signal Processing Toolbox (fir1, butter, freqz, filtfilt, grpdelay)
% Output:   figures/*.png and results.txt (all printed numbers)
%
% The script has no local functions, so it also runs section by section.
% =========================================================================

clear; close all; clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
figuresDir = fullfile(scriptDir, 'figures');
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end

% Save everything printed in the Command Window to results.txt
resultsFile = fullfile(scriptDir, 'results.txt');
if exist(resultsFile, 'file')
    delete(resultsFile);
end
diary(resultsFile);

%% Environment check
fprintf('MATLAB version: %s\n', version);
spt = ver('signal');
if isempty(spt) || ~license('test', 'Signal_Toolbox')
    diary off;
    error('Signal Processing Toolbox is required (fir1, butter, freqz, filtfilt).');
end
fprintf('Signal Processing Toolbox: version %s, license available\n\n', spt.Version);

% MATLAB default colors
blue   = [0      0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];
yellow = [0.9290 0.6940 0.1250];
purple = [0.4940 0.1840 0.5560];
green  = [0.4660 0.6740 0.1880];
gray   = [0.65 0.65 0.65];
black  = [0 0 0];

rmse = @(y, ref) sqrt(mean((y - ref).^2));
toDb = @(g) 20*log10(max(abs(g), 1e-12));     % floor avoids log10(0)

%% =========================================================================
% PART A: Filter a sensor signal
%   2 s at 1000 Hz. Wanted: 5 Hz + smaller 12 Hz.
%   Unwanted: 50 Hz and 137 Hz interference + random noise.
% =========================================================================
fprintf('==================== PART A: Sensor signal ====================\n');

Fs = 1000;
t = (0:1/Fs:2-1/Fs)';
rng(7);
clean = sin(2*pi*5*t) + 0.35*sin(2*pi*12*t);
noise = 0.35*sin(2*pi*50*t) + 0.20*sin(2*pi*137*t) + 0.25*randn(size(t));
x = clean + noise;

% Two 20 Hz low-pass designs
fc = 20;
bFIR = fir1(60, fc/(Fs/2), 'low');              % order 60 -> 61 taps
[bIIR, aIIR] = butter(4, fc/(Fs/2), 'low');     % 4th-order Butterworth

% Zero-phase (forward-backward) filtering, offline
yFIR = filtfilt(bFIR, 1, x);
yIIR = filtfilt(bIIR, aIIR, x);

fCheck = [5 12 50 137];                         % frequencies discussed in the report

%% -------------------------------------------------------------------------
% A1: Time-domain comparison over 0.2 s, all signals on the same axes
% -------------------------------------------------------------------------
fprintf('Running A1: Time-domain comparison...\n');

figA1 = figure('Name', 'A1: Sensor time domain', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 1000 750]);

sections = [1.0 1.2;      % middle of the recording (steady state)
            0.0 0.2];     % start of the recording (edge effects)
sectionTitles = {'Middle section, 1.0-1.2 s', 'Start of recording, 0-0.2 s (edge region)'};

for s = 1:2
    subplot(2, 1, s);
    idx = t >= sections(s, 1) & t < sections(s, 2);
    plot(t(idx), x(idx), 'Color', gray, 'LineWidth', 0.8); hold on;
    plot(t(idx), clean(idx), '--', 'Color', black, 'LineWidth', 1.8);
    plot(t(idx), yFIR(idx), 'Color', blue, 'LineWidth', 1.4);
    plot(t(idx), yIIR(idx), 'Color', orange, 'LineWidth', 1.4);
    hold off;
    title(['Sensor signal: ' sectionTitles{s}]);
    xlabel('Time (s)'); ylabel('Amplitude (a.u.)');
    legend('Noisy input', 'Clean reference', 'FIR output (order 60)', ...
        'IIR output (Butterworth, order 4)', 'Location', 'eastoutside');
    grid on;
    xlim(sections(s, :));
    ylim([-2.2, 2.2]);
end
saveas(figA1, fullfile(figuresDir, 'partA1_time_domain.png'));

%% -------------------------------------------------------------------------
% A2: Magnitude responses with freqz (single pass and filtfilt)
%   filtfilt applies the filter twice, so its magnitude is |H|^2,
%   i.e. twice the dB value of a single pass.
% -------------------------------------------------------------------------
fprintf('Running A2: Frequency responses...\n');

nFreq = 8192;
[HF, fH] = freqz(bFIR, 1, nFreq, Fs);
HI = freqz(bIIR, aIIR, nFreq, Fs);

figA2 = figure('Name', 'A2: Sensor filter responses', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 1000 750]);

views = {[0 500], [-160 5], 'Full range, 0-500 Hz';
         [0 60],  [-60 3],  'Zoom on the pass band and transition, 0-60 Hz'};
for s = 1:2
    subplot(2, 1, s);
    plot(fH, toDb(HF), 'Color', blue, 'LineWidth', 1.5); hold on;
    plot(fH, toDb(HI), 'Color', orange, 'LineWidth', 1.5);
    plot(fH, 2*toDb(HF), '--', 'Color', blue, 'LineWidth', 1);
    plot(fH, 2*toDb(HI), '--', 'Color', orange, 'LineWidth', 1);
    yl = views{s, 2};
    plot([fc fc], yl, 'k-', 'LineWidth', 1);                       % 20 Hz cutoff
    plot([50 50 NaN 137 137], [yl NaN yl], ':', 'Color', gray, 'LineWidth', 1.2);
    if s == 2
        plot([0 60], [-3 -3], ':', 'Color', black);
        plot([0 60], [-6 -6], ':', 'Color', black);
        text(1, -2, '-3 dB'); text(1, -7.5, '-6 dB');
    end
    hold off;
    title(['Low-pass magnitude responses (f_c = 20 Hz): ' views{s, 3}]);
    xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
    legend('FIR, single pass', 'IIR, single pass', 'FIR with filtfilt (|H|^2)', ...
        'IIR with filtfilt (|H|^2)', '20 Hz cutoff', '50 / 137 Hz interference', ...
        'Location', 'eastoutside');
    grid on;
    xlim(views{s, 1});
    ylim(yl);
end
saveas(figA2, fullfile(figuresDir, 'partA2_frequency_response.png'));

gF = abs(freqz(bFIR, 1, fCheck, Fs));
gI = abs(freqz(bIIR, aIIR, fCheck, Fs));
fprintf('\n  Filter gain at the frequencies of interest\n');
fprintf('  Freq (Hz) | FIR 1-pass | FIR filtfilt | IIR 1-pass | IIR filtfilt\n');
for k = 1:numel(fCheck)
    fprintf('  %8g  | %7.2f dB | %8.2f dB  | %7.2f dB | %8.2f dB\n', ...
        fCheck(k), toDb(gF(k)), 2*toDb(gF(k)), toDb(gI(k)), 2*toDb(gI(k)));
end
gF20 = abs(freqz(bFIR, 1, [20 21], Fs));      % freqz needs at least 2 frequencies
gI20 = abs(freqz(bIIR, aIIR, [20 21], Fs));
fprintf('  Gain at 20 Hz: FIR %.2f dB, IIR %.2f dB (single pass)\n', toDb(gF20(1)), toDb(gI20(1)));

%% -------------------------------------------------------------------------
% A3: Single-sided amplitude spectra
%   N = 2000, df = 0.5 Hz, so 5, 12, 50 and 137 Hz all sit on exact bins.
% -------------------------------------------------------------------------
fprintf('\nRunning A3: Spectra...\n');

N = length(x);
S = [clean x yFIR yIIR];                 % one signal per column
P2 = abs(fft(S) / N);                    % fft works on each column
P1 = P2(1:N/2+1, :);
P1(2:end-1, :) = 2*P1(2:end-1, :);
fS = Fs*(0:N/2)' / N;
binIdx = round(fCheck / (Fs/N)) + 1;

figA3 = figure('Name', 'A3: Sensor spectra', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 1000 850]);
specNames  = {'Noisy input', 'FIR output', 'IIR output'};
specColors = [gray; blue; orange];
for s = 1:3
    subplot(3, 1, s);
    col = s + 1;                          % column in S (1 is the clean signal)
    plot(fS, toDb(P1(:, col)), 'Color', specColors(s, :), 'LineWidth', 1); hold on;
    plot(fS(binIdx), toDb(P1(binIdx, col)), 'ko', 'MarkerSize', 7, 'LineWidth', 1.2);
    for k = 1:numel(fCheck)
        text(fCheck(k) + 2, toDb(P1(binIdx(k), col)) + 8, ...
            sprintf('%g Hz', fCheck(k)), 'FontSize', 8);
    end
    plot([fc fc], [-180 20], 'k-', 'LineWidth', 1);
    hold off;
    title(['Single-sided amplitude spectrum: ' specNames{s}]);
    xlabel('Frequency (Hz)'); ylabel('Amplitude (dB re 1)');
    legend(specNames{s}, 'Bins at 5, 12, 50, 137 Hz', '20 Hz cutoff', 'Location', 'eastoutside');
    grid on;
    xlim([0 200]);
    ylim([-180 10]);
end
saveas(figA3, fullfile(figuresDir, 'partA3_spectra.png'));

fprintf('\n  Spectrum amplitude at the frequencies of interest (linear)\n');
fprintf('  Freq (Hz) |  Clean  |  Noisy  |   FIR      |   IIR\n');
for k = 1:numel(fCheck)
    fprintf('  %8g  | %7.4f | %7.4f | %10.3e | %10.3e\n', fCheck(k), P1(binIdx(k), :));
end

%% -------------------------------------------------------------------------
% A4: RMSE against the known clean signal
%   Whole signal, interior (0.1-1.9 s) and edges (first + last 0.1 s).
% -------------------------------------------------------------------------
fprintf('\nRunning A4: RMSE...\n');

edgeLen  = round(0.1*Fs);
isEdge   = false(N, 1);
isEdge([1:edgeLen, N-edgeLen+1:N]) = true;
isInner  = ~isEdge;

outs     = [x yFIR yIIR];
outNames = {'Noisy input', 'FIR output', 'IIR output'};
rmseTab  = zeros(3, 3);                  % rows: signal, cols: whole / interior / edges
for s = 1:3
    rmseTab(s, 1) = rmse(outs(:, s), clean);
    rmseTab(s, 2) = rmse(outs(isInner, s), clean(isInner));
    rmseTab(s, 3) = rmse(outs(isEdge, s), clean(isEdge));
end

fprintf('\n  RMSE against the clean signal\n');
fprintf('  Signal       | Whole 0-2 s | Interior 0.1-1.9 s | Edges (first+last 0.1 s)\n');
for s = 1:3
    fprintf('  %-12s |   %.4f    |       %.4f       |   %.4f\n', outNames{s}, rmseTab(s, :));
end

figA4 = figure('Name', 'A4: Sensor RMSE', 'NumberTitle', 'off', 'Color', 'w');
hb = bar(rmseTab');
hb(1).FaceColor = gray; hb(2).FaceColor = blue; hb(3).FaceColor = orange;
for s = 1:3
    for c = 1:3
        text(c + (s-2)*0.225, rmseTab(s, c) + 0.012, sprintf('%.3f', rmseTab(s, c)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end
set(gca, 'XTickLabel', {'Whole 0-2 s', 'Interior 0.1-1.9 s', 'Edges (first + last 0.1 s)'});
title('RMSE against the known clean signal');
xlabel('Part of the recording'); ylabel('RMSE (a.u.)');
legend(outNames, 'Location', 'northeast');
grid on;
xlim([0.5 3.5]);
ylim([0, 1.15*max(rmseTab(:))]);
saveas(figA4, fullfile(figuresDir, 'partA4_rmse.png'));

%% -------------------------------------------------------------------------
% A5: Design comparison numbers
% -------------------------------------------------------------------------
fprintf('\nRunning A5: Design comparison...\n');
gdF = grpdelay(bFIR, 1, [5 12], Fs);
gdI = grpdelay(bIIR, aIIR, [5 12], Fs);
fprintf('  FIR: %d coefficients (b), a = 1, order 60\n', numel(bFIR));
fprintf('  IIR: %d b + %d a = %d coefficients, order 4\n', ...
    numel(bIIR), numel(aIIR), numel(bIIR) + numel(aIIR));
fprintf('  Single-pass group delay at 5 / 12 Hz: FIR %.1f / %.1f samples, IIR %.1f / %.1f samples\n', ...
    gdF, gdI);
fprintf('  (1 sample = 1 ms at 1000 Hz. filtfilt cancels this delay offline.)\n');

%% =========================================================================
% PART B: Reduce a 50 Hz hum in audio (Handel)
% =========================================================================
fprintf('\n==================== PART B: Audio hum ====================\n');

% Same as "load handel", but kept in a struct so Fs from Part A is not overwritten
handel = load('handel');                 % provides y and Fs
xClean = handel.y(:);
FsA    = handel.Fs;
tAudio = (0:numel(xClean)-1)' / FsA;

fprintf('Handel: Fs = %d Hz, %d samples, %.2f s\n', FsA, numel(xClean), numel(xClean)/FsA);
if FsA <= 102
    error('Fs must be above 102 Hz to represent 50 Hz with the 51 Hz stop-band edge.');
end

humAmp = 0.15;
xHum = xClean + humAmp*sin(2*pi*50*tAudio);

% Narrow band-stop (as given) and a wider one for comparison
bandN = [49 51];
bandW = [45 55];
fprintf('Normalized stop-band edges: narrow [%.5f %.5f], wide [%.5f %.5f] (must be < 1)\n', ...
    bandN/(FsA/2), bandW/(FsA/2));
[bN, aN] = butter(2, bandN/(FsA/2), 'stop');
[bW, aW] = butter(2, bandW/(FsA/2), 'stop');

yAudio = filtfilt(bN, aN, xHum);         % narrow
yWide  = filtfilt(bW, aW, xHum);         % wide

% The same filters on the clean music show how much useful audio they remove
cleanN = filtfilt(bN, aN, xClean);
cleanW = filtfilt(bW, aW, xClean);

%% -------------------------------------------------------------------------
% B1: Waveform before and after, same axes
% -------------------------------------------------------------------------
fprintf('Running B1: Audio waveforms...\n');

secStart = 1.0;                          % change to look at another 0.1 s section
secIdx = tAudio >= secStart & tAudio < secStart + 0.1;

figB1 = figure('Name', 'B1: Audio waveforms', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 1000 800]);
panels = {xHum, 'Hum added (0.15 \times sin(2\pi 50 t))', purple;
          yAudio, 'Filtered, narrow band-stop 49-51 Hz', blue;
          yWide, 'Filtered, wide band-stop 45-55 Hz', green};
for s = 1:3
    subplot(3, 1, s);
    plot(tAudio(secIdx), xClean(secIdx), 'Color', gray, 'LineWidth', 2.2); hold on;
    plot(tAudio(secIdx), panels{s, 1}(secIdx), 'Color', panels{s, 3}, 'LineWidth', 1.1);
    hold off;
    title(['Handel, ' sprintf('%.1f-%.1f s: ', secStart, secStart + 0.1) panels{s, 2}]);
    xlabel('Time (s)'); ylabel('Amplitude (normalized)');
    legend('Clean original', panels{s, 2}, 'Location', 'eastoutside');
    grid on;
    xlim([secStart, secStart + 0.1]);
    ylim([-1, 1]);
end
saveas(figB1, fullfile(figuresDir, 'partB1_waveform.png'));

%% -------------------------------------------------------------------------
% B2: Spectra around 50 Hz
%   Uses an even number of samples so the single-sided pattern applies.
% -------------------------------------------------------------------------
fprintf('Running B2: Audio spectra...\n');

Na = 2*floor(numel(xClean)/2);
SA = [xClean(1:Na) xHum(1:Na) yAudio(1:Na) yWide(1:Na)];
PA2 = abs(fft(SA) / Na);
PA1 = PA2(1:Na/2+1, :);
PA1(2:end-1, :) = 2*PA1(2:end-1, :);
fA = FsA*(0:Na/2)' / Na;

figB2 = figure('Name', 'B2: Audio spectra', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 1000 850]);
specB = {2, 'Hum added', purple; 3, 'Narrow band-stop 49-51 Hz', blue; 4, 'Wide band-stop 45-55 Hz', green};
for s = 1:3
    subplot(3, 1, s);
    plot(fA, toDb(PA1(:, 1)), 'Color', gray, 'LineWidth', 1.6); hold on;
    plot(fA, toDb(PA1(:, specB{s, 1})), 'Color', specB{s, 3}, 'LineWidth', 1);
    plot([50 50], [-140 0], 'k:', 'LineWidth', 1.2);
    text(51, -10, '50 Hz', 'FontSize', 9);
    hold off;
    title(['Amplitude spectrum around 50 Hz: clean vs ' specB{s, 2}]);
    xlabel('Frequency (Hz)'); ylabel('Amplitude (dB re 1)');
    legend('Clean original', specB{s, 2}, '50 Hz', 'Location', 'eastoutside');
    grid on;
    xlim([20 100]);
    ylim([-140 0]);
end
saveas(figB2, fullfile(figuresDir, 'partB2_spectrum.png'));

%% -------------------------------------------------------------------------
% B3 (optional): Notch filter responses, narrow vs wide
% -------------------------------------------------------------------------
fprintf('Running B3: Notch responses...\n');

fN = linspace(30, 70, 4001);
HN = freqz(bN, aN, fN, FsA);
HW = freqz(bW, aW, fN, FsA);

figB3 = figure('Name', 'B3: Notch responses', 'NumberTitle', 'off', 'Color', 'w');
plot(fN, 2*toDb(HN), 'Color', blue, 'LineWidth', 1.5); hold on;
plot(fN, 2*toDb(HW), 'Color', green, 'LineWidth', 1.5);
plot([30 70], [-3 -3], 'k:');
plot([50 50], [-120 5], ':', 'Color', gray, 'LineWidth', 1.2);
hold off;
title('Band-stop responses with filtfilt (|H|^2), Fs = 8192 Hz');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
legend('Narrow 49-51 Hz', 'Wide 45-55 Hz', '-3 dB', '50 Hz', 'Location', 'southwest');
grid on;
xlim([30 70]);
ylim([-120 5]);
saveas(figB3, fullfile(figuresDir, 'partB3_notch_response.png'));

%% -------------------------------------------------------------------------
% B4: Measure the 50 Hz amplitude before and after filtering
%   Method: project the signal onto a 50 Hz complex exponential,
%   A = 2/N * |sum x[n] exp(-j 2 pi 50 n / Fs)|  (a single-frequency DFT).
%   Measured over the whole signal and over the interior (1 s trimmed
%   from each end) to separate steady-state attenuation from edge effects.
% -------------------------------------------------------------------------
fprintf('\nRunning B4: 50 Hz measurement...\n');

amp50 = @(v, tt) 2*abs(sum(v .* exp(-1j*2*pi*50*tt))) / numel(v);
inner = tAudio >= 1 & tAudio <= tAudio(end) - 1;

sigB  = {xClean, xHum, yAudio, yWide};
namesB = {'Clean original', 'Hum added', 'Narrow 49-51 Hz', 'Wide 45-55 Hz'};
fprintf('  Signal           | 50 Hz amp (whole) | 50 Hz amp (interior)\n');
a50 = zeros(4, 2);
for s = 1:4
    a50(s, 1) = amp50(sigB{s}, tAudio);
    a50(s, 2) = amp50(sigB{s}(inner), tAudio(inner));
    fprintf('  %-16s |     %.5f       |     %.5f\n', namesB{s}, a50(s, :));
end
fprintf('  Measured hum reduction (interior): narrow %.1f dB, wide %.1f dB\n', ...
    toDb(a50(3, 2)/a50(2, 2)), toDb(a50(4, 2)/a50(2, 2)));

gN50 = abs(freqz(bN, aN, [50 51], FsA)); gW50 = abs(freqz(bW, aW, [50 51], FsA));
fprintf('  Filter response at 50 Hz: narrow %.1f dB (filtfilt %.1f dB), wide %.1f dB (filtfilt %.1f dB)\n', ...
    toDb(gN50(1)), 2*toDb(gN50(1)), toDb(gW50(1)), 2*toDb(gW50(1)));

% Useful audio removed and overall error
rmsClean = sqrt(mean(xClean.^2));
fprintf('\n  Clean music RMS: %.4f\n', rmsClean);
fprintf('  Music removed by narrow filter (RMS of filtered clean - clean): %.5f (%.1f dB re music)\n', ...
    rmse(cleanN, xClean), toDb(rmse(cleanN, xClean)/rmsClean));
fprintf('  Music removed by wide filter:                                  %.5f (%.1f dB re music)\n', ...
    rmse(cleanW, xClean), toDb(rmse(cleanW, xClean)/rmsClean));
fprintf('  RMSE vs clean: hum added %.5f, narrow %.5f, wide %.5f\n', ...
    rmse(xHum, xClean), rmse(yAudio, xClean), rmse(yWide, xClean));

% Edge effects: residual error in the first/last 0.5 s vs the rest
edgeA = tAudio < 0.5 | tAudio > tAudio(end) - 0.5;
fprintf('  Narrow filter error RMS: edges (first+last 0.5 s) %.5f, rest %.5f\n', ...
    rmse(yAudio(edgeA), xClean(edgeA)), rmse(yAudio(~edgeA), xClean(~edgeA)));
fprintf('  Wide filter error RMS:   edges (first+last 0.5 s) %.5f, rest %.5f\n', ...
    rmse(yWide(edgeA), xClean(edgeA)), rmse(yWide(~edgeA), xClean(~edgeA)));

%% -------------------------------------------------------------------------
% B5: Listening test at the same playback gain
%   One common gain for all signals (not soundsc, which scales each
%   signal separately and would hide level differences).
% -------------------------------------------------------------------------
%   If playback does not work (for example in MATLAB Online), set
%   saveAudio = true. The same four signals, with the same gain, are written
%   as WAV files to audio/ so they can be downloaded and played on any
%   device. audio/ is in .gitignore: the files are for listening only and
%   are not part of the submission.
playAudio = true;       % play in MATLAB
saveAudio = true;       % also write audio/*.wav for listening elsewhere

gain = 0.9 / max(abs([xClean; xHum; yAudio; yWide]));
playList  = {xClean, xHum, yAudio, yWide};
wavNames  = {'1_clean.wav', '2_hum_added.wav', '3_narrow_49_51Hz.wav', '4_wide_45_55Hz.wav'};
fprintf('\nRunning B5: Listening test, common gain %.3f for all signals\n', gain);

if playAudio
    try
        for s = 1:4
            fprintf('  Playing: %s\n', namesB{s});
            sound(gain*playList{s}, FsA);
            pause(numel(playList{s})/FsA + 0.7);
        end
    catch err
        fprintf('  Playback not available: %s\n', err.message);
    end
end

if saveAudio
    audioDir = fullfile(scriptDir, 'audio');
    if ~exist(audioDir, 'dir')
        mkdir(audioDir);
    end
    for s = 1:4
        audiowrite(fullfile(audioDir, wavNames{s}), gain*playList{s}, FsA);
    end
    fprintf('  WAV files for listening saved to: %s\n', audioDir);
end

fprintf('\nFigures saved to: %s\n', figuresDir);
fprintf('Numbers saved to: %s\n', resultsFile);
diary off;
