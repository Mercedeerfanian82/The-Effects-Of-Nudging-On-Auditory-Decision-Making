% Generate auditory stimuli for an online SNR-validation experiment.
%
% Fixed acoustic parameters:
% - Gaussian white noise masker generated with randn
% - 1000 Hz pure-tone pip
% - 48 kHz sampling rate
% - 2.5 s total stimulus duration
% - 0.15 noise RMS
% - 200 ms tone duration
% - 20 ms linear onset and offset ramps
% - only SNR varies across signal-present conditions

clear;
clc;

% Fixed stimulus parameters.
fs = 48000;
dur = 2.5;          % total stimulus duration in seconds
noiseRMS = 0.15;
toneFreq = 1000;    % pure-tone frequency in Hz
pipDur = 0.20;      % 200 ms tone duration
rampDur = 0.02;     % 20 ms onset and offset ramps

% Experimental SNR values in dB.
snrDBs = [-18 -20 -22 -24 -26 -28 -30];

% Derived sample counts.
nSamples = round(dur * fs);
nPipSamples = round(pipDur * fs);
nRampSamples = round(rampDur * fs);

% Centre the tone pip temporally within the full stimulus.
pipStart = floor((nSamples - nPipSamples) / 2) + 1;
pipEnd = pipStart + nPipSamples - 1;

% Time vector for the tone pip only.
tPip = (0:nPipSamples - 1) / fs;

% Build a 20 ms linear onset and 20 ms linear offset ramp.
envelope = ones(1, nPipSamples);
onRamp = linspace(0, 1, nRampSamples);
offRamp = linspace(1, 0, nRampSamples);
envelope(1:nRampSamples) = onRamp;
envelope(end - nRampSamples + 1:end) = offRamp;

% Keep output files separate from the script.
outputDir = fullfile(pwd, 'stimuli');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

generatedFiles = strings(numel(snrDBs) * 2, 1);
generatedSNRs = strings(numel(snrDBs) * 2, 1);
fileIdx = 1;

for iSNR = 1:numel(snrDBs)
    snrDB = snrDBs(iSNR);

    % Generate independent Gaussian white noise for the signal-present file.
    noise = randn(1, nSamples);
    noise = noise / rms(noise) * noiseRMS;

    % Calculate and apply the required pre-ramp tone RMS for this SNR.
    toneRMS = noiseRMS * 10^(snrDB / 20);
    tone = sin(2 * pi * toneFreq * tPip);
    tone = tone / rms(tone) * toneRMS;

    % Apply the fixed 20 ms onset and offset ramps after RMS scaling.
    tone = tone .* envelope;

    % Embed the centred tone pip in the Gaussian white noise.
    signalStimulus = noise;
    signalStimulus(pipStart:pipEnd) = signalStimulus(pipStart:pipEnd) + tone;

    % Generate independent Gaussian white noise for the noise-only file.
    noiseOnlyStimulus = randn(1, nSamples);
    noiseOnlyStimulus = noiseOnlyStimulus / rms(noiseOnlyStimulus) * noiseRMS;

    % Avoid clipping without changing the relative SNR within any stimulus.
    peakAbs = max([abs(signalStimulus), abs(noiseOnlyStimulus)]);
    if peakAbs > 0.999
        signalStimulus = signalStimulus / peakAbs * 0.999;
        noiseOnlyStimulus = noiseOnlyStimulus / peakAbs * 0.999;
        warning('Scaled SNR %d dB pair by %.4f to avoid clipping.', ...
            snrDB, 0.999 / peakAbs);
    end

    % Save the signal-present and noise-only mp3 files at 64 kHz.
    snrLabel = sprintf('m%d', abs(snrDB));
    signalFilename = sprintf('snr_%s_signal.mp3', snrLabel);
    noiseOnlyFilename = sprintf('snr_%s_noiseonly.mp3', snrLabel);
    signalPath = fullfile(outputDir, signalFilename);
    noiseOnlyPath = fullfile(outputDir, noiseOnlyFilename);

    audiowrite(signalPath, signalStimulus, fs);
    audiowrite(noiseOnlyPath, noiseOnlyStimulus, fs);

    generatedFiles(fileIdx) = signalFilename;
    generatedSNRs(fileIdx) = sprintf('%d dB', snrDB);
    fileIdx = fileIdx + 1;

    generatedFiles(fileIdx) = noiseOnlyFilename;
    generatedSNRs(fileIdx) = 'noise only';
    fileIdx = fileIdx + 1;
end

% Print a concise generation summary.
fprintf('\nGenerated mp3 files in: %s\n\n', outputDir);
fprintf('%-24s %s\n', 'Filename', 'Condition');
fprintf('%-24s %s\n', repmat('-', 1, 24), repmat('-', 1, 16));
for iFile = 1:numel(generatedFiles)
    fprintf('%-24s %s\n', generatedFiles(iFile), generatedSNRs(iFile));
end
