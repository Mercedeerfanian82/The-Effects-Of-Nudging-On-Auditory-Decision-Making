%% Clean Gorilla CSV files and save as XLSX
% 1. Remove all rows where "Zone Type" = "fixation"
% 2. Remove rows where "display" is:
%       trial1
%       transition
%       block*
%       end
%       empty
% 3. Remove specified metadata / unnecessary columns
% 4. Save cleaned data as XLSX files in a separate folder
%
% Original CSV files are NOT overwritten.

clear;
clc;

%% Input directory
dataDir = '/Users/mercedeerfanian/Desktop/Basic nudge/online study/data';

%% Output directory
outputDir = fullfile(dataDir, 'cleaned_xlsx');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% Find all CSV files
files = dir(fullfile(dataDir, '*.csv'));

if isempty(files)
    error('No CSV files found in: %s', dataDir);
end

%% Columns to remove
columnsToRemove = [
    "Event Index"
    "UTC Timestamp"
    "UTC Date and Time"
    "Local Timestamp"
    "Local Timezone"
    "Local Date and Time"
    "Experiment ID"
    "Experiment Version"
    "Tree Node Key"
    "Repeat Key"
    "Schedule ID"
    "Participant Public ID"
    "Participant Starting Group"
    "Participant Status"
    "Participant Completion Code"
    "Participant External Session ID"
    "Participant Device Type"
    "Participant Device"
    "Participant OS"
    "Participant Browser"
    "Participant Monitor Size"
    "Participant Viewport Size"
    "Checkpoint"
    "Reaction Onset"
    "Response Type"
    "detected"	
    "Var53"
    "ANSWER"
    "Room ID"
    "Room Order"
    "Task Name"
    "Task Version"
    "Manipulation: Spreadsheet"
    "Spreadsheet Name"
    "Spreadsheet Row"
    "Trial Number"
    "Screen Number"
    "Screen Name"
    "Zone Name"
    "X Coordinate"
    "Y Coordinate"
    "Timed Out"
    "randomise_blocks"
    "randomise_trials"
];

%% Process each CSV file
for f = 1:length(files)

    inputFile = fullfile(dataDir, files(f).name);

    fprintf('\nProcessing: %s\n', files(f).name);

    %% Read CSV
    T = readtable(inputFile, ...
        'VariableNamingRule', 'preserve', ...
        'TextType', 'string');

    originalN = height(T);
    originalCols = width(T);

    %% ---------------------------------------------------------------
    % STEP 1: Remove rows where Zone Type = fixation
    % ---------------------------------------------------------------

    if ismember("Zone Type", string(T.Properties.VariableNames))

        zoneType = strtrim(string(T.("Zone Type")));

        removeFixation = strcmpi(zoneType, "fixation");

        nFixation = sum(removeFixation);

        T(removeFixation, :) = [];

        fprintf('Removed %d fixation rows.\n', nFixation);

    else
        warning('"Zone Type" column not found in %s.', files(f).name);
    end


    %% ---------------------------------------------------------------
    % STEP 2: Remove unwanted display rows
    % ---------------------------------------------------------------

    if ismember("display", string(T.Properties.VariableNames))

        displayValue = strtrim(string(T.("display")));

        % Empty or missing display
        removeEmpty = ...
            ismissing(displayValue) | ...
            displayValue == "";

        % Practice trials
        removeTrial1 = strcmpi(displayValue, "trial1");

        % Transition screen
        removeTransition = strcmpi(displayValue, "transition");

        % End screen
        removeEnd = strcmpi(displayValue, "end");

        % Anything beginning with "block"
        % e.g. block1, block2, block3, block4
        removeBlock = startsWith( ...
            displayValue, ...
            "block", ...
            'IgnoreCase', true);

        % Combine all exclusions
        removeRows = ...
            removeEmpty | ...
            removeTrial1 | ...
            removeTransition | ...
            removeEnd | ...
            removeBlock;

        nDisplayRemoved = sum(removeRows);

        T(removeRows, :) = [];

        fprintf('Removed %d unwanted display rows.\n', ...
            nDisplayRemoved);

    else
        warning('"display" column not found in %s.', files(f).name);
    end


    %% ---------------------------------------------------------------
    % STEP 3: Remove unwanted columns
    % ---------------------------------------------------------------

    existingColumns = string(T.Properties.VariableNames);

    % Find only columns that actually exist
    colsFound = intersect( ...
        columnsToRemove, ...
        existingColumns, ...
        'stable');

    if ~isempty(colsFound)

        T(:, cellstr(colsFound)) = [];

        fprintf('Removed %d unwanted columns.\n', ...
            length(colsFound));

    else
        fprintf('No listed unwanted columns found.\n');
    end


    %% ---------------------------------------------------------------
    % STEP 4: Save cleaned file as XLSX
    % ---------------------------------------------------------------

    [~, baseName, ~] = fileparts(files(f).name);

    outputFile = fullfile( ...
        outputDir, ...
        [baseName '_cleaned.xlsx']);

    writetable(T, outputFile);


    %% ---------------------------------------------------------------
    % Summary
    % ---------------------------------------------------------------

    fprintf('Original rows:      %d\n', originalN);
    fprintf('Remaining rows:     %d\n', height(T));
    fprintf('Original columns:   %d\n', originalCols);
    fprintf('Remaining columns:  %d\n', width(T));
    fprintf('Saved to:\n%s\n', outputFile);

end

disp(' ');
disp('Finished cleaning all Gorilla files.');
disp('Cleaned XLSX files saved in:');
disp(outputDir);