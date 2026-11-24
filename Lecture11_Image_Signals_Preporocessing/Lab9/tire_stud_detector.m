% =========================================================================
% Digital Signal Processing - Lecture 11, Lab 9: Tire Stud Detector
% File: tire_stud_detector.m
% Description: detects metal studs on tires with image preprocessing and
%   connected-component analysis, and classifies each tire as STUDDED or
%   NON-STUDDED. Built on the course skeleton; every TODO is filled in.
% Pipeline per image:
%   1) read and resize          2) grayscale
%   3) tire mask (dark object on a white background), shrunk inwards so
%      the bright highlight along the tire's outline is excluded
%   4) candidate studs: bright, small, round spots, found with a Gaussian-
%      smoothed blob detector (Laplacian of Gaussian) and a local-contrast
%      test (brighter than the rubber around them)
%   5) connected components + regionprops
%   6) filters: area, circularity 4*pi*A/P^2, eccentricity
%   7) decision: number of studs (and density per tire area)
%   8) figures: input, candidate mask, final detection
% Every figure is saved to figures/*.png (all at once at the end; a failed
% save only warns). No local functions are used.
% Requires: Image Processing Toolbox.
% =========================================================================

clear; clc; close all;

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

% The studded image in this folder is a .jpeg file (the skeleton says .jpg).
imageFiles = {'studded_tire.jpeg', 'summer_tire.jpg'};

% ---------- Parameters (chosen for these two images, at scale 0.5) ----------
scale       = 0.5;    % resize factor
tireThresh  = 0.60;   % tire = darker than this (background is near-white)
edgeMargin  = 12;     % px removed along the tire outline (shoulder highlights)
blobSigma   = 1.5;    % LoG scale in px: a stud is about 2*sqrt(2)*sigma = 4 px across
blobThresh  = 0.08;   % minimum blob response
contrastWin = 15;     % px, window of the local median (rubber around a stud)
pixContrast = 0.20;   % candidate pixels: at least this much brighter than the rubber around
minContrast = 0.35;   % a stud's brightest pixel must be this much brighter than the rubber
minA = 4;             % min area of a stud (px)
maxA = 120;           % max area of a stud (px)
minCirc = 0.6;        % minimum circularity 4*pi*A/P^2
maxEcc = 0.85;        % maximum eccentricity
minStuds = 10;        % decision: more studs than this -> STUDDED
decisionLabels = {'NON-STUDDED TIRE', 'STUDDED TIRE'};

results = struct('file', {}, 'tireArea', {}, 'candidates', {}, 'studs', {}, 'density', {}, 'studded', {});

for i = 1:numel(imageFiles)

    % ---------- 1) Read & resize ----------
    I = imread(fullfile(scriptDir, imageFiles{i}));
    I = imresize(I, scale);   % optional scaling

    % ---------- 2) Convert to grayscale ----------
    if size(I, 3) == 3
        Igray = im2double(rgb2gray(I));
    else
        Igray = im2double(I);
    end

    % ---------- 3) Create tire mask ----------
    % The tire is darker than the near-white background. Holes (bright
    % tread blocks in the light, the rim of the summer tire) are filled,
    % an opening removes thin bright-edge fringes, and only the largest
    % object, the tire itself, is kept.
    tireMask = Igray < tireThresh;
    tireMask = imfill(tireMask, 'holes');
    tireMask = imopen(tireMask, strel('disk', 15));
    tireMask = bwareaopen(tireMask, 500);
    tireMask = bwareafilt(tireMask, 1);
    % Search area: the mask shrunk by edgeMargin px, because the rounded
    % shoulder of the tire shows a bright highlight along its outline.
    searchMask = imerode(tireMask, strel('disk', edgeMargin));
    tireArea = nnz(tireMask);

    % ---------- 4) Candidate studs ----------
    % Studs are small, round, bright points INSIDE the tire.
    % a) Blob detector: the scale-normalised Laplacian of Gaussian responds
    %    strongly to a round bright spot of about the stud's size and only
    %    weakly to thin lines and edges. Its Gaussian part also smooths
    %    JPEG noise (the "Gaussian blur" cleaning step).
    hLoG = fspecial('log', 2 * ceil(3 * blobSigma) + 1, blobSigma);
    blob = -blobSigma^2 * imfilter(Igray, hLoG, 'replicate');
    % b) Local contrast: brightness above the median of the surrounding
    %    rubber. Metal studs are much brighter than the rubber around them;
    %    highlights on rubber edges are only slightly brighter.
    localContrast = Igray - medfilt2(Igray, [contrastWin contrastWin], 'symmetric');

    % The contrast test is also applied per pixel, so that a stud does not
    % merge with a neighbouring highlight into one large component.
    cand = (blob > blobThresh) & (localContrast > pixContrast) & searchMask;
    cand = bwareaopen(cand, 3);           % remove 1-2 px noise
    cand = imfill(cand, 'holes');

    % ---------- 5) Connected components ----------
    CC = bwconncomp(cand);
    stats = regionprops(CC, localContrast, 'Area', 'Perimeter', 'Eccentricity', 'MaxIntensity');

    % ---------- 6) Filter candidates ----------
    studMask = false(size(cand));
    studCount = 0;
    for k = 1:numel(stats)
        A = stats(k).Area;
        P = max(stats(k).Perimeter, eps);
        circ = 4 * pi * A / P^2;
        if A >= minA && A <= maxA && circ >= minCirc && stats(k).Eccentricity <= maxEcc ...
                && stats(k).MaxIntensity >= minContrast
            studMask(CC.PixelIdxList{k}) = true;
            studCount = studCount + 1;
        end
    end

    % ---------- 7) Decision rule ----------
    density = studCount / tireArea * 1e4;   % studs per 10 000 tire pixels
    isStudded = (studCount > minStuds);

    results(i).file = imageFiles{i};
    results(i).tireArea = tireArea;
    results(i).candidates = CC.NumObjects;
    results(i).studs = studCount;
    results(i).density = density;
    results(i).studded = isStudded;
    fprintf('%s: %d x %d px, tire %d px, %d candidates, %d studs, %.2f studs / 10^4 px -> %s\n', ...
        imageFiles{i}, size(Igray, 2), size(Igray, 1), tireArea, CC.NumObjects, studCount, density, ...
        decisionLabels{isStudded + 1});

    % ---------- 8) Visualization ----------
    fig = figure('Position', [100 100 1500 560]); theme(fig, 'light');
    subplot(1, 3, 1);
    imshow(I); title(sprintf('Input: %s', imageFiles{i}), 'Interpreter', 'none');

    subplot(1, 3, 2);
    imshow(cand); title(sprintf('Candidate studs (binary): %d', CC.NumObjects));

    subplot(1, 3, 3);
    imshow(I); hold on;
    visboundaries(imdilate(studMask, strel('disk', 2)), 'LineWidth', 0.7);
    hold off;

    if isStudded
        title(sprintf('STUDDED TIRE (studs: %d)', studCount));
    else
        title(sprintf('NON-STUDDED TIRE (studs: %d)', studCount));
    end
    figList(end + 1, :) = {fig, sprintf('fig%d_result_%s.png', i, erase(imageFiles{i}, {'.jpeg', '.jpg'}))};

    % Added: intermediate steps (tire mask, blob response, local contrast).
    fig = figure('Position', [100 100 1500 560]); theme(fig, 'light');
    tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    nexttile; imshow(tireMask); hold on; visboundaries(searchMask, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 0.7); hold off;
    title(sprintf('Tire mask (white), search area (orange): %.1f %% of image', 100 * tireArea / numel(tireMask)));
    nexttile; imshow(blob, [0 0.2]); title(sprintf('LoG blob response (\\sigma = %.1f)', blobSigma));
    nexttile; imshow(localContrast, [-0.2 0.6]); title('Local contrast I - median_{15x15}(I)');
    figList(end + 1, :) = {fig, sprintf('fig%d_steps_%s.png', i, erase(imageFiles{i}, {'.jpeg', '.jpg'}))};
end

disp(struct2table(results));

%% Save all figures
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
