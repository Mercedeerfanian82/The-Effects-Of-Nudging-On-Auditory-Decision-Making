%% Analyse Gorilla gap attention-check trials
%
% IMPORTANT LOGIC:
%
% - trial1 = PRACTICE and is excluded.
%
% - A trial is identified by:
%       Participant Private ID + display + trial_type
%
% - Repeated rows with the same trial_type belong to ONE trial.
%
% Example:
%
%   trial2 | gap_trial_002.mp3 | 32 | AUDIO PLAY REQUESTED
%   trial2 | gap_trial_002.mp3 | 32 | detected
%
% These are ONE gap trial, not two.
%
% - If the grouped gap trial contains Response = "detected":
%       HIT
%
% - If no "detected" response exists:
%       MISS
%
% - Reaction Time is taken ONLY from the "detected" row.
%
% - Participant summary reports:
%       Total Gap Trials
%       Gap Hits
%       Gap Misses
%       Gap Detection Percent
%       Mean Gap Reaction Time

clear;
clc;

%% ---------------------------------------------------------------
% DIRECTORIES
% ---------------------------------------------------------------

dataDir = ...
    '/Users/mercedeerfanian/Desktop/Basic nudge/online study/data';

outputDir = ...
    fullfile(dataDir, 'attention_check_results');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% ---------------------------------------------------------------
% FIND ORIGINAL CSV FILES
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

    existingColumns = ...
        string(T.Properties.VariableNames);

    missingColumns = ...
        setdiff(requiredColumns, existingColumns);

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
    % EXCLUDE PRACTICE DISPLAY trial1
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
    % KEEP ONLY ROWS THAT HAVE A VALID TRIAL IDENTIFIER
    % -----------------------------------------------------------

    validTrialRow = ...
        ~ismissing(participant) & ...
        participant ~= "" & ...
        ~ismissing(displayName) & ...
        displayName ~= "" & ...
        ~ismissing(trialNumber) & ...
        trialNumber ~= "";

    participant = ...
        participant(validTrialRow);

    displayName = ...
        displayName(validTrialRow);

    trialNumber = ...
        trialNumber(validTrialRow);

    audio = ...
        audio(validTrialRow);

    response = ...
        response(validTrialRow);

    reactionTime = ...
        reactionTime(validTrialRow);

    %% -----------------------------------------------------------
    % STEP 3:
    % GROUP REPEATED EVENT ROWS INTO ONE TRIAL
    %
    % SAME:
    %   Participant Private ID
    %   display
    %   trial_type
    %
    % = ONE TRIAL
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
    % PREALLOCATE GAP-TRIAL OUTPUT
    % -----------------------------------------------------------

    GapParticipant = strings(0,1);
    GapDisplay = strings(0,1);
    GapTrialNumber = strings(0,1);
    GapAudioFile = strings(0,1);

    GapDetected = [];
    GapOutcome = strings(0,1);
    GapRT = [];

    %% -----------------------------------------------------------
    % STEP 4:
    % ANALYSE EACH UNIQUE TRIAL
    % -----------------------------------------------------------

    gapCounter = 0;

    for g = 1:nTrials

        rowsThisTrial = ...
            trialGroup == uniqueGroups(g);

        %% Get all audio values in this trial
        audioThisTrial = ...
            lower(strtrim(audio(rowsThisTrial)));

        %% Identify gap stimulus
        isGapAudio = ...
            startsWith(audioThisTrial, "gap_trial_") & ...
            endsWith(audioThisTrial, ".mp3");

        %% Skip non-gap trials
        if ~any(isGapAudio)
            continue;
        end

        gapCounter = ...
            gapCounter + 1;

        %% -------------------------------------------------------
        % STORE TRIAL INFORMATION
        % -------------------------------------------------------

        localParticipant = ...
            participant(rowsThisTrial);

        localDisplay = ...
            displayName(rowsThisTrial);

        localTrial = ...
            trialNumber(rowsThisTrial);

        localAudio = ...
            audio(rowsThisTrial);

        GapParticipant(gapCounter,1) = ...
            localParticipant(1);

        GapDisplay(gapCounter,1) = ...
            localDisplay(1);

        GapTrialNumber(gapCounter,1) = ...
            localTrial(1);

        %% Store actual gap filename
        gapAudioIndex = ...
            find(isGapAudio, 1, 'first');

        GapAudioFile(gapCounter,1) = ...
            localAudio(gapAudioIndex);

        %% -------------------------------------------------------
        % CHECK RESPONSE
        % -------------------------------------------------------

        responseThisTrial = ...
            strtrim(response(rowsThisTrial));

        detectedRows = ...
            strcmpi(responseThisTrial, "detected");

        %% -------------------------------------------------------
        % HIT
        % -------------------------------------------------------

        if any(detectedRows)

            GapDetected(gapCounter,1) = 1;
            GapOutcome(gapCounter,1) = "Hit";

            %% Reaction Time only from detected row
            rtThisTrial = ...
                reactionTime(rowsThisTrial);

            detectedRTs = ...
                rtThisTrial(detectedRows);

            detectedRTs = ...
                detectedRTs(~isnan(detectedRTs));

            if ~isempty(detectedRTs)

                GapRT(gapCounter,1) = ...
                    detectedRTs(1);

            else

                GapRT(gapCounter,1) = NaN;

            end

        %% -------------------------------------------------------
        % MISS
        % -------------------------------------------------------

        else

            GapDetected(gapCounter,1) = 0;
            GapOutcome(gapCounter,1) = "Miss";
            GapRT(gapCounter,1) = NaN;

        end

    end

    %% -----------------------------------------------------------
    % CREATE GAP-TRIAL DETAIL TABLE
    % -----------------------------------------------------------

    GapTrialResults = table( ...
        GapParticipant, ...
        GapDisplay, ...
        GapTrialNumber, ...
        GapAudioFile, ...
        GapDetected, ...
        GapOutcome, ...
        GapRT);

    GapTrialResults.Properties.VariableNames = {
        'Participant Private ID'
        'display'
        'trial_type'
        'audio'
        'Detected'
        'Outcome'
        'Reaction Time'
    };

    fprintf('Unique MAIN-TASK gap trials found: %d\n', ...
        height(GapTrialResults));

    %% -----------------------------------------------------------
    % STEP 5:
    % PARTICIPANT-LEVEL SUMMARY
    % -----------------------------------------------------------

    participants = ...
        unique(GapParticipant, 'stable');

    nParticipants = ...
        length(participants);

    TotalGapTrials = ...
        zeros(nParticipants,1);

    GapHits = ...
        zeros(nParticipants,1);

    GapMisses = ...
        zeros(nParticipants,1);

    GapDetectionPercent = ...
        nan(nParticipants,1);

    MeanGapReactionTime = ...
        nan(nParticipants,1);

    for p = 1:nParticipants

        participantRows = ...
            GapParticipant == participants(p);

        %% Total UNIQUE gap trials
        TotalGapTrials(p) = ...
            sum(participantRows);

        %% Hits
        GapHits(p) = ...
            sum( ...
            GapDetected(participantRows) == 1);

        %% Misses
        GapMisses(p) = ...
            sum( ...
            GapDetected(participantRows) == 0);

        %% Detection %
        if TotalGapTrials(p) > 0

            GapDetectionPercent(p) = ...
                100 * ...
                GapHits(p) / ...
                TotalGapTrials(p);

        end

        %% -------------------------------------------------------
        % Mean RT:
        % detected gap trials only
        % -------------------------------------------------------

        hitRows = ...
            participantRows & ...
            GapDetected == 1;

        participantRT = ...
            GapRT(hitRows);

        participantRT = ...
            participantRT(~isnan(participantRT));

        if ~isempty(participantRT)

            MeanGapReactionTime(p) = ...
                mean(participantRT);

        end

    end

    %% -----------------------------------------------------------
    % PARTICIPANT SUMMARY TABLE
    % -----------------------------------------------------------

    ParticipantSummary = table( ...
        participants, ...
        TotalGapTrials, ...
        GapHits, ...
        GapMisses, ...
        GapDetectionPercent, ...
        MeanGapReactionTime);

    ParticipantSummary.Properties.VariableNames = {
        'Participant Private ID'
        'Total Gap Trials'
        'Gap Hits'
        'Gap Misses'
        'Gap Detection Percent'
        'Mean Gap Reaction Time'
    };

    %% -----------------------------------------------------------
    % STEP 6:
    % SAVE RESULTS
    % -----------------------------------------------------------

    [~, baseName, ~] = ...
        fileparts(files(f).name);

    outputFile = ...
        fullfile( ...
        outputDir, ...
        [baseName '_attention_checks.xlsx']);

    writetable( ...
        ParticipantSummary, ...
        outputFile, ...
        'Sheet', 'Participant Summary');

    writetable( ...
        GapTrialResults, ...
        outputFile, ...
        'Sheet', 'Gap Trial Details');

    %% -----------------------------------------------------------
    % DISPLAY RESULTS
    % -----------------------------------------------------------

    disp(' ');
    disp(ParticipantSummary);

    fprintf('\nSaved to:\n%s\n', outputFile);

end

disp(' ');
disp('============================================');
disp('Attention-check analysis complete.');
disp('Practice trial1 was excluded.');
disp('============================================');