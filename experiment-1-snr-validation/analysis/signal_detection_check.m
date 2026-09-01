%% Analyse Gorilla SNR signal-detection trials
%
% LOGIC:
%
% - trial1 = PRACTICE and is excluded.
%
% - One trial is identified by:
%       Participant Private ID + display + trial_type
%
% - Repeated rows with the same trial_type belong to ONE trial.
%
% Example:
%
%   trial2 | snr_m26_signal.mp3 | 41 | AUDIO PLAY REQUESTED
%   trial2 | snr_m26_signal.mp3 | 41 | detected
%
% These two rows are ONE trial.
%
% - Only signal-present files are analysed:
%       snr_m18_signal.mp3
%       snr_m20_signal.mp3
%       snr_m22_signal.mp3
%       snr_m24_signal.mp3
%       snr_m26_signal.mp3
%       snr_m28_signal.mp3
%       snr_m30_signal.mp3
%
% - gap_trial_*.mp3 files are excluded.
% - noise-only files are excluded.
%
% - If Response contains "detected":
%       HIT / correct
%
% - If no "detected" response exists:
%       MISS / incorrect
%
% - Reaction Time is taken ONLY from the detected row.
%
% - Results are calculated per:
%       Participant Private ID
%       SNR
%
% Outputs:
%   1. Participant x SNR Summary
%   2. Trial Details
%
% Run this code on the ORIGINAL Gorilla CSV files.

clear;
clc;

%% ---------------------------------------------------------------
% DIRECTORIES
% ---------------------------------------------------------------

dataDir = ...
    '/Users/mercedeerfanian/Desktop/Basic nudge/online study/data';

outputDir = ...
    fullfile(dataDir, 'snr_signal_results');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% ---------------------------------------------------------------
% FIND CSV FILES
% ---------------------------------------------------------------

files = dir(fullfile(dataDir, '*.csv'));

if isempty(files)
    error('No CSV files found in: %s', dataDir);
end

%% ---------------------------------------------------------------
% PROCESS EACH CSV FILE
% ---------------------------------------------------------------

for f = 1:length(files)

    inputFile = fullfile(dataDir, files(f).name);

    fprintf('\n============================================\n');
    fprintf('Processing: %s\n', files(f).name);
    fprintf('============================================\n');

    %% Read Gorilla CSV
    T = readtable( ...
        inputFile, ...
        'VariableNamingRule', 'preserve', ...
        'TextType', 'string');

    %% -----------------------------------------------------------
    % CHECK REQUIRED COLUMNS
    % -----------------------------------------------------------

    requiredColumns = [
        "Participant Private ID"
        "display"
        "trial_type"
        "audio"
        "Response"
        "Reaction Time"
    ];

    existingColumns = string(T.Properties.VariableNames);

    missingColumns = setdiff(requiredColumns, existingColumns);

    if ~isempty(missingColumns)

        error( ...
            'Missing required column(s): %s', ...
            strjoin(missingColumns, ', '));

    end

    %% -----------------------------------------------------------
    % EXTRACT VARIABLES
    % -----------------------------------------------------------

    participant = ...
        strtrim(string(T.("Participant Private ID")));

    displayName = ...
        strtrim(string(T.("display")));

    trialNumber = ...
        strtrim(string(T.("trial_type")));

    audio = ...
        strtrim(string(T.("audio")));

    response = ...
        strtrim(string(T.("Response")));

    %% Reaction Time
    if isnumeric(T.("Reaction Time"))

        reactionTime = ...
            double(T.("Reaction Time"));

    else

        reactionTime = ...
            str2double(string(T.("Reaction Time")));

    end

    %% -----------------------------------------------------------
    % STEP 1:
    % EXCLUDE PRACTICE trial1
    % -----------------------------------------------------------

    keepRow = ...
        ~strcmpi(displayName, "trial1");

    participant = participant(keepRow);
    displayName = displayName(keepRow);
    trialNumber = trialNumber(keepRow);
    audio = audio(keepRow);
    response = response(keepRow);
    reactionTime = reactionTime(keepRow);

    %% -----------------------------------------------------------
    % STEP 2:
    % KEEP ONLY VALID TRIAL ROWS
    % -----------------------------------------------------------

    validTrialRow = ...
        ~ismissing(participant) & ...
        participant ~= "" & ...
        ~ismissing(displayName) & ...
        displayName ~= "" & ...
        ~ismissing(trialNumber) & ...
        trialNumber ~= "";

    participant = participant(validTrialRow);
    displayName = displayName(validTrialRow);
    trialNumber = trialNumber(validTrialRow);
    audio = audio(validTrialRow);
    response = response(validTrialRow);
    reactionTime = reactionTime(validTrialRow);

    %% -----------------------------------------------------------
    % STEP 3:
    % GROUP REPEATED EVENT ROWS INTO UNIQUE TRIALS
    %
    % Same participant + display + trial_type = ONE trial
    % -----------------------------------------------------------

    trialKey = ...
        participant + "|" + ...
        displayName + "|" + ...
        trialNumber;

    [~, ~, trialGroup] = ...
        unique(trialKey, 'stable');

    uniqueGroups = ...
        unique(trialGroup, 'stable');

    nTrials = ...
        length(uniqueGroups);

    fprintf('Unique main-task trials found: %d\n', nTrials);

    %% -----------------------------------------------------------
    % PREALLOCATE SIGNAL-TRIAL OUTPUT
    % -----------------------------------------------------------

    SignalParticipant = strings(0,1);
    SignalDisplay = strings(0,1);
    SignalTrialNumber = strings(0,1);
    SignalAudioFile = strings(0,1);

    SNR_dB = [];
    Detected = [];
    Outcome = strings(0,1);
    SignalRT = [];

    signalCounter = 0;

    %% -----------------------------------------------------------
    % STEP 4:
    % ANALYSE EACH UNIQUE TRIAL
    % -----------------------------------------------------------

    for g = 1:nTrials

        rowsThisTrial = ...
            trialGroup == uniqueGroups(g);

        %% Audio values for this grouped trial
        audioThisTrial = ...
            lower(strtrim(audio(rowsThisTrial)));

        %% -------------------------------------------------------
        % IDENTIFY SIGNAL-PRESENT SNR TRIAL
        % -------------------------------------------------------

        isSignalAudio = ...
            startsWith(audioThisTrial, "snr_m") & ...
            contains(audioThisTrial, "_signal.mp3");

        %% Explicitly exclude gap trials
        isGapAudio = ...
            startsWith(audioThisTrial, "gap_trial_");

        %% Explicitly exclude noise-only trials
        isNoiseOnly = ...
            contains(audioThisTrial, "_noiseonly.mp3");

        %% Keep only signal-present trials
        if ~any(isSignalAudio) || any(isGapAudio) || any(isNoiseOnly)
            continue;
        end

        signalCounter = signalCounter + 1;

        %% -------------------------------------------------------
        % STORE BASIC TRIAL INFORMATION
        % -------------------------------------------------------

        localParticipant = ...
            participant(rowsThisTrial);

        localDisplay = ...
            displayName(rowsThisTrial);

        localTrial = ...
            trialNumber(rowsThisTrial);

        localAudio = ...
            audio(rowsThisTrial);

        SignalParticipant(signalCounter,1) = ...
            localParticipant(1);

        SignalDisplay(signalCounter,1) = ...
            localDisplay(1);

        SignalTrialNumber(signalCounter,1) = ...
            localTrial(1);

        %% Store actual signal filename
        signalIndexLocal = ...
            find(isSignalAudio, 1, 'first');

        SignalAudioFile(signalCounter,1) = ...
            localAudio(signalIndexLocal);

        %% -------------------------------------------------------
        % EXTRACT SNR FROM FILENAME
        %
        % Example:
        % snr_m26_signal.mp3 -> -26
        % -------------------------------------------------------

        thisFilename = ...
            lower(SignalAudioFile(signalCounter));

        snrToken = regexp( ...
            thisFilename, ...
            'snr_m(\d+)_signal\.mp3', ...
            'tokens', ...
            'once');

        if isempty(snrToken)

            SNR_dB(signalCounter,1) = NaN;

        else

            SNR_dB(signalCounter,1) = ...
                -str2double(snrToken{1});

        end

        %% -------------------------------------------------------
        % CHECK WHETHER TONE WAS DETECTED
        % -------------------------------------------------------

        responseThisTrial = ...
            strtrim(response(rowsThisTrial));

        detectedRows = ...
            strcmpi(responseThisTrial, "detected");

        %% HIT
        if any(detectedRows)

            Detected(signalCounter,1) = 1;
            Outcome(signalCounter,1) = "Hit";

            %% RT from detected row only
            rtThisTrial = ...
                reactionTime(rowsThisTrial);

            detectedRTs = ...
                rtThisTrial(detectedRows);

            detectedRTs = ...
                detectedRTs(~isnan(detectedRTs));

            if ~isempty(detectedRTs)

                SignalRT(signalCounter,1) = ...
                    detectedRTs(1);

            else

                SignalRT(signalCounter,1) = NaN;

            end

        %% MISS
        else

            Detected(signalCounter,1) = 0;
            Outcome(signalCounter,1) = "Miss";
            SignalRT(signalCounter,1) = NaN;

        end

    end

    %% -----------------------------------------------------------
    % CREATE TRIAL-LEVEL TABLE
    % -----------------------------------------------------------

    SignalTrialResults = table( ...
        SignalParticipant, ...
        SignalDisplay, ...
        SignalTrialNumber, ...
        SignalAudioFile, ...
        SNR_dB, ...
        Detected, ...
        Outcome, ...
        SignalRT);

    SignalTrialResults.Properties.VariableNames = {
        'Participant Private ID'
        'display'
        'trial_type'
        'audio'
        'SNR dB'
        'Detected'
        'Outcome'
        'Reaction Time'
    };

    fprintf('Unique signal-present trials found: %d\n', ...
        height(SignalTrialResults));

    %% -----------------------------------------------------------
    % STEP 5:
    % PARTICIPANT x SNR SUMMARY
    % -----------------------------------------------------------

    participants = ...
        unique(SignalParticipant, 'stable');

    snrLevels = [
        -18
        -20
        -22
        -24
        -26
        -28
        -30
    ];

    SummaryParticipant = strings(0,1);
    SummarySNR = [];
    TotalSignalTrials = [];
    Hits = [];
    Misses = [];
    AccuracyPercent = [];
    MeanReactionTime = [];

    summaryCounter = 0;

    for p = 1:length(participants)

        for s = 1:length(snrLevels)

            rowsThisCondition = ...
                SignalParticipant == participants(p) & ...
                SNR_dB == snrLevels(s);

            %% Skip condition if participant has no trials
            if ~any(rowsThisCondition)
                continue;
            end

            summaryCounter = ...
                summaryCounter + 1;

            SummaryParticipant(summaryCounter,1) = ...
                participants(p);

            SummarySNR(summaryCounter,1) = ...
                snrLevels(s);

            %% Number of unique signal trials
            TotalSignalTrials(summaryCounter,1) = ...
                sum(rowsThisCondition);

            %% Hits
            Hits(summaryCounter,1) = ...
                sum( ...
                Detected(rowsThisCondition) == 1);

            %% Misses
            Misses(summaryCounter,1) = ...
                sum( ...
                Detected(rowsThisCondition) == 0);

            %% Accuracy %
            AccuracyPercent(summaryCounter,1) = ...
                100 * ...
                Hits(summaryCounter,1) / ...
                TotalSignalTrials(summaryCounter,1);

            %% Mean RT for detected trials only
            rtRows = ...
                rowsThisCondition & ...
                Detected == 1;

            participantRT = ...
                SignalRT(rtRows);

            participantRT = ...
                participantRT(~isnan(participantRT));

            if ~isempty(participantRT)

                MeanReactionTime(summaryCounter,1) = ...
                    mean(participantRT);

            else

                MeanReactionTime(summaryCounter,1) = NaN;

            end

        end

    end

    %% -----------------------------------------------------------
    % CREATE PARTICIPANT x SNR SUMMARY TABLE
    % -----------------------------------------------------------

    ParticipantSNRSummary = table( ...
        SummaryParticipant, ...
        SummarySNR, ...
        TotalSignalTrials, ...
        Hits, ...
        Misses, ...
        AccuracyPercent, ...
        MeanReactionTime);

    ParticipantSNRSummary.Properties.VariableNames = {
        'Participant Private ID'
        'SNR dB'
        'Total Signal Trials'
        'Hits'
        'Misses'
        'Accuracy Percent'
        'Mean Reaction Time'
    };

    %% -----------------------------------------------------------
    % STEP 6:
    % OPTIONAL OVERALL PARTICIPANT SUMMARY
    % -----------------------------------------------------------

    nParticipants = ...
        length(participants);

    OverallTotalTrials = zeros(nParticipants,1);
    OverallHits = zeros(nParticipants,1);
    OverallMisses = zeros(nParticipants,1);
    OverallAccuracyPercent = nan(nParticipants,1);
    OverallMeanRT = nan(nParticipants,1);

    for p = 1:nParticipants

        participantRows = ...
            SignalParticipant == participants(p);

        OverallTotalTrials(p) = ...
            sum(participantRows);

        OverallHits(p) = ...
            sum(Detected(participantRows) == 1);

        OverallMisses(p) = ...
            sum(Detected(participantRows) == 0);

        if OverallTotalTrials(p) > 0

            OverallAccuracyPercent(p) = ...
                100 * ...
                OverallHits(p) / ...
                OverallTotalTrials(p);

        end

        rtRows = ...
            participantRows & ...
            Detected == 1;

        participantRT = ...
            SignalRT(rtRows);

        participantRT = ...
            participantRT(~isnan(participantRT));

        if ~isempty(participantRT)

            OverallMeanRT(p) = ...
                mean(participantRT);

        end

    end

    OverallParticipantSummary = table( ...
        participants, ...
        OverallTotalTrials, ...
        OverallHits, ...
        OverallMisses, ...
        OverallAccuracyPercent, ...
        OverallMeanRT);

    OverallParticipantSummary.Properties.VariableNames = {
        'Participant Private ID'
        'Total Signal Trials'
        'Hits'
        'Misses'
        'Overall Accuracy Percent'
        'Overall Mean Reaction Time'
    };

    %% -----------------------------------------------------------
    % STEP 7:
    % SAVE XLSX
    % -----------------------------------------------------------

    [~, baseName, ~] = ...
        fileparts(files(f).name);

    outputFile = ...
        fullfile( ...
        outputDir, ...
        [baseName '_snr_signal_analysis.xlsx']);

    %% Participant x SNR summary
    writetable( ...
        ParticipantSNRSummary, ...
        outputFile, ...
        'Sheet', 'Participant x SNR');

    %% Overall participant summary
    writetable( ...
        OverallParticipantSummary, ...
        outputFile, ...
        'Sheet', 'Overall Participant');

    %% Trial-level details
    writetable( ...
        SignalTrialResults, ...
        outputFile, ...
        'Sheet', 'Signal Trial Details');

    %% -----------------------------------------------------------
    % DISPLAY
    % -----------------------------------------------------------

    disp(' ');
    disp(ParticipantSNRSummary);

    fprintf('\nSaved to:\n%s\n', outputFile);

end

disp(' ');
disp('============================================');
disp('SNR signal analysis complete.');
disp('Gap trials and noise-only trials excluded.');
disp('Practice trial1 excluded.');
disp('============================================');