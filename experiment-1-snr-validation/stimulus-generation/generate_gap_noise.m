%% Generate Gaussian white-noise stimuli with 50 ms silent gaps
% For online SNR validation study
% Based on Erfanian et al. gap-detection procedure
% Sequence duration adapted to match current 2.5 s stimuli

clear;
clc;

%% Fixed stimulus parameters
fs = 48000;
dur = 2.5;              % total stimulus duration (s)
noiseRMS = 0.15;        % same RMS as all other noise stimuli
gapDur = 0.050;         % 50 ms silent gap

% Keep gap away from stimulus onset and offset
gapMargin = 0.5;        % 500 ms minimum distance from each edge

% Number of gap stimuli to generate
nStimuli = 30;

stimDir = '/Users/mercedeerfanian/Desktop/Basic nudge/online study/gap_trials';

if ~exist(stimDir, 'dir')
    mkdir(stimDir);
end

%% Derived parameters
nSamples = round(dur * fs);
gapSamples = round(gapDur * fs);

minGapStart = round(gapMargin * fs);
maxGapStart = round((dur - gapMargin - gapDur) * fs);

%% Generate stimuli
for i = 1:nStimuli

    % Generate Gaussian white noise
    noise = randn(1, nSamples);

    % Match RMS to all other study stimuli
    noise = noise / rms(noise) * noiseRMS;

    % Select random gap location within allowed interval
    gapStart = randi([minGapStart, maxGapStart]);

    gapIdx = gapStart:(gapStart + gapSamples - 1);

    % Insert 50 ms silence
    noise(gapIdx) = 0;

    % Safety check for clipping
    if max(abs(noise)) > 1
        warning('Stimulus %d exceeds digital range.', i);
    end

    % Save mp3 file
    filename = sprintf('gap_trial_%03d.mp3', i);

    audiowrite( ...
        fullfile(stimDir, filename), ...
        noise, ...
        fs);

    fprintf( ...
        'Generated %s | gap onset = %.3f s\n', ...
        filename, ...
        gapStart/fs);
end

disp('All silence-gap stimuli generated.');