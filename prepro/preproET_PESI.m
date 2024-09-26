% This function preprocesses eye tracking data for the PESI task collected
% with a LiveTrack Lightning Eye Tracker. It takes the filename of the csv
% and the path of the file as input. All data is saved in the same folder
% as the input file. 
% 
% Detection of events (blinks, saccades, glissades and fixations) is based
% on NYSTRÖM & HOLMQVIST (2010).
%
% (c) Irene Sophia Plank 10planki@gmail.com

function preproET_PESI(subID, dir_path, run1, run2)

%% read in data and calculate values

% get subject ID from the filename
fprintf('\nNow processing subject %s.\n', subID);

% set options for reading in the data
opts = delimitedTextImportOptions("NumVariables", 11);
opts.DataLines = [2, Inf];
opts.Delimiter = ",";
opts.VariableNames = ["timestamp", "trigger", "leftScreenX", "leftScreenY", "rightScreenX", "rightScreenY", "leftPupilMajorAxis", "leftPupilMinorAxis", "rightPupilMajorAxis", "rightPupilMinorAxis", "comment"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% get the filename and read in the data
file = dir([dir_path filesep 'PESI-ET-' subID '_20*.csv']);
if length(file) ~= 1
    warning('Wrong number of files for %s!', subID)
    return
end
tbl = readtable([file.folder filesep file.name], opts); 

% if only one eye was tracked, check that both runs same eye and then
% rename the columns
if any(ismember(tbl.Properties.VariableNames,'ScreenX'))
    warning('Only one eye tracked for %s', subID)
    return
end

%% add trial information

% find the break between runs
idx_break = find(strcmp(tbl.comment,"Comment"), 1);

% find trial indices
idx = find(extractBefore(tbl.comment,4) == "pic");

% if break was not logged but all pics are there determine idx_break based
% on the pictures
if isempty(idx_break) && length(idx) == 19200
    idx_break = idx(19200/2) + ...
        (idx((19200/2)+1) - idx(19200/2))/2;
end

% if only one run can be used, ignore the other
if isempty(run1)
    idx = idx(idx >= idx_break);
elseif isempty(run2)
    idx = idx(idx <= idx_break);
end

% create empty columns to be filled with information
tbl.trialNo   = nan(height(tbl),1);
tbl.trialVid  = strings(height(tbl),1);
tbl.trialPic  = nan(height(tbl),1);

% loop through the indices and add the information from the comment
for i = 1:(length(idx)-1)

    % get end of picture
    if (idx(i+1)-idx(i)) >= 20
        idx_end = idx(i)+19;
    else
        idx_end = idx(i+1)-1;
    end

    % divide string
    trialinfo = strsplit(tbl.comment(idx(i,1)), "_");
    % trial counter depends on run
    if idx(i,1) < idx_break
        tbl.trialNo(idx(i):(idx_end))   = str2double(trialinfo(5));
    else
        tbl.trialNo(idx(i):(idx_end))   = str2double(trialinfo(5))+32;
    end
    % trial video
    tbl.trialVid(idx(i):(idx_end))  = strjoin(trialinfo(2:4), "_");
    % pic number
    tbl.trialPic(idx(i):(idx_end))  = str2double(trialinfo(6));

end

% check if there are correct number of trials
trl_total = (length(run1) + length(run2)) * 32;
trls = unique(tbl.trialNo);
if sum(~isnan(trls)) ~= trl_total
    warning("The dataset %s only has %d of %d trials!", ...
        subID, sum(~isnan(trls)), trl_total)
end

%% classification of events

% generate parameters for NH2010 classification code.
ETparams = defaultParameters;
ETparams.screen.resolution              = [1920   1080]; % screen resolution in pixel
ETparams.screen.size                    = [0.533 0.300]; % screen size in m
ETparams.screen.viewingDist             = 0.57;          % viewing distance in m
ETparams.screen.dataCenter              = [0 0];         % center of screen has these coordinates in data
ETparams.screen.subjectStraightAhead    = [0 0];         % specify the screen coordinate that is straight ahead of the subject. Just specify the middle of the screen unless its important to you to get this very accurate!

% do the classification for the specified eye for run 1
if ~isempty(run1)
    if run1 == 'r'
        tbl.xPixel(1:idx_break) = ...
            tbl.rightScreenX(1:idx_break)*...
            (ETparams.screen.resolution(1)/(ETparams.screen.size(1)*1000));
        tbl.yPixel(1:idx_break) = ...
            tbl.rightScreenY(1:idx_break)*...
            (ETparams.screen.resolution(2)/(ETparams.screen.size(2)*1000));
        tbl.pupilDiameter(1:idx_break) = ...
            mean([tbl.rightPupilMajorAxis(1:idx_break),...
            tbl.rightPupilMinorAxis(1:idx_break)],2);
    elseif run1 == 'l'
        tbl.xPixel(1:idx_break) = ...
            tbl.leftScreenX(1:idx_break)*...
            (ETparams.screen.resolution(1)/(ETparams.screen.size(1)*1000));
        tbl.yPixel(1:idx_break) = ...
            tbl.leftScreenY(1:idx_break)*...
            (ETparams.screen.resolution(2)/(ETparams.screen.size(2)*1000));
        tbl.pupilDiameter(1:idx_break) = ...
            mean([tbl.leftPupilMajorAxis(1:idx_break),...
            tbl.leftPupilMinorAxis(1:idx_break)],2);
    else
        warning('Wrong specification of eye of first run')
    end
    % run the NH2010 classifier code on first run
    [classificationData1,ETparams1]   = runNH2010Classification(...
        tbl.xPixel(1:idx_break),tbl.yPixel(1:idx_break),...
        tbl.pupilDiameter(1:idx_break),ETparams);
    % merge glissades with saccades
    classificationData1 = mergeSaccadesAndGlissades(classificationData1);
    if isfield(classificationData1,'glissade')
        classificationData1 = rmfield(classificationData1,'glissade');    
    end
    % check the amount of missing data
    qBlink          = bounds2bool(classificationData1.blink.on,classificationData1.blink.off,length(classificationData1.deg.vel)).';
    qMissingOrBlink = qBlink | isnan(classificationData1.deg.vel);
    if mean(qMissingOrBlink) >= 1/3
        warning('No run 1: %s has more than 33%% blinks or missing.', subID)
        clear classificationData1
        run1 = '';
    end
end

% do the classification for the specified eye for run 2
if ~isempty(run2)
    if run2 == 'r'
        tbl.xPixel(idx_break:height(tbl)) = ...
            tbl.rightScreenX(idx_break:height(tbl))*...
            (ETparams.screen.resolution(1)/(ETparams.screen.size(1)*1000));
        tbl.yPixel(idx_break:height(tbl)) = ...
            tbl.rightScreenY(idx_break:height(tbl))*...
            (ETparams.screen.resolution(2)/(ETparams.screen.size(2)*1000));
        tbl.pupilDiameter(idx_break:height(tbl)) = ...
            mean([tbl.rightPupilMajorAxis(idx_break:height(tbl)),...
            tbl.rightPupilMinorAxis(idx_break:height(tbl))],2);
    elseif run2 == 'l'
        tbl.xPixel(idx_break:height(tbl)) = ...
            tbl.leftScreenX(idx_break:height(tbl))*...
            (ETparams.screen.resolution(1)/(ETparams.screen.size(1)*1000));
        tbl.yPixel(idx_break:height(tbl)) = ...
            tbl.leftScreenY(idx_break:height(tbl))*...
            (ETparams.screen.resolution(2)/(ETparams.screen.size(2)*1000));
        tbl.pupilDiameter(idx_break:height(tbl)) = ...
            mean([tbl.leftPupilMajorAxis(idx_break:height(tbl)),...
            tbl.leftPupilMinorAxis(idx_break:height(tbl))],2);
    else
        warning('Wrong specification of eye of second run')
    end
    % run the NH2010 classifier code on first run
    [classificationData2,ETparams2]   = runNH2010Classification(...
        tbl.xPixel(idx_break:height(tbl)),tbl.yPixel(idx_break:height(tbl)),...
        tbl.pupilDiameter(idx_break:height(tbl)),ETparams);
    % merge glissades with saccades
    classificationData2 = mergeSaccadesAndGlissades(classificationData2);
    if isfield(classificationData2,'glissade')
        classificationData2 = rmfield(classificationData2,'glissade');    
    end
    % check the amount of missing data
    qBlink          = bounds2bool(classificationData2.blink.on,...
        classificationData2.blink.off,...
        length(classificationData2.deg.vel)).';
    qMissingOrBlink = qBlink | isnan(classificationData2.deg.vel);
    if mean(qMissingOrBlink) >= 1/3
        warning('No run 2: %s has more than 33%% blinks or missing.', subID)
        clear classificationData2
        run2 = '';
    end
end

if ~exist('classificationData1', 'var') && ~exist('classificationData2', 'var')
    return
end


%% create output tables

% fixations
if ~isempty(run1)
    fn = fieldnames(classificationData1.fixation);
    for k = 1:numel(fn)
        if size(classificationData1.fixation.(fn{k}),1) < size(classificationData1.fixation.(fn{k}),2)
            classificationData1.fixation.(fn{k}) = classificationData1.fixation.(fn{k}).';
        end
    end
    tbl_fix1 = struct2table(classificationData1.fixation);
    tbl_fix1.eye = repmat(run1,height(tbl_fix1),1);
    tbl_fix1.run = ones(height(tbl_fix1),1);
end
if ~isempty(run2)
    fn = fieldnames(classificationData2.fixation);
    for k = 1:numel(fn)
        if size(classificationData2.fixation.(fn{k}),1) < size(classificationData2.fixation.(fn{k}),2)
            classificationData2.fixation.(fn{k}) = classificationData2.fixation.(fn{k}).';
        end
    end
    tbl_fix2 = struct2table(classificationData2.fixation);
    tbl_fix2.eye = repmat(run2,height(tbl_fix2),1);
    tbl_fix2.run = ones(height(tbl_fix2),1)+1;
    % adjust the indices
    tbl_fix2.on  = tbl_fix2.on  + idx_break - 1;
    tbl_fix2.off = tbl_fix2.off + idx_break - 1;
end

% combine both runs
if exist('tbl_fix1', 'var') && exist('tbl_fix2', 'var')
    tbl_fix = [tbl_fix1; tbl_fix2];
elseif exist('tbl_fix1', 'var')
    tbl_fix = tbl_fix1;
else
    tbl_fix = tbl_fix2;
end

% saccades
if ~isempty(run1)
    fn = fieldnames(classificationData1.saccade);
    for k = 1:numel(fn)
        if size(classificationData1.saccade.(fn{k}),1) < size(classificationData1.saccade.(fn{k}),2)
            classificationData1.saccade.(fn{k}) = classificationData1.saccade.(fn{k}).';
        end
    end
    n_sac = size(classificationData1.saccade.on);
    if n_sac > 0
        classificationData1.saccade.offsetVelocityThreshold = ...
            classificationData1.saccade.offsetVelocityThreshold(1:n_sac);
        classificationData1.saccade.peakVelocityThreshold = repmat( ...
            classificationData1.saccade.peakVelocityThreshold, ...
            size(classificationData1.saccade.peakVelocity,1), ...
            size(classificationData1.saccade.peakVelocity,2));
        classificationData1.saccade.onsetVelocityThreshold = repmat( ...
            classificationData1.saccade.onsetVelocityThreshold, ...
            size(classificationData1.saccade.peakVelocity,1), ...
            size(classificationData1.saccade.peakVelocity,2));
        tbl_sac1 = struct2table(classificationData1.saccade);
        tbl_sac1.eye  = repmat(run1,height(tbl_sac1),1);
        tbl_sac1.run  = ones(height(tbl_sac1),1);
    end
end

if ~isempty(run2)
    fn = fieldnames(classificationData2.saccade);
    for k = 1:numel(fn)
        if size(classificationData2.saccade.(fn{k}),1) < size(classificationData2.saccade.(fn{k}),2)
            classificationData2.saccade.(fn{k}) = classificationData2.saccade.(fn{k}).';
        end
    end
    n_sac = size(classificationData2.saccade.on);
    if n_sac > 0
        classificationData2.saccade.offsetVelocityThreshold = ...
            classificationData2.saccade.offsetVelocityThreshold(1:n_sac);
        classificationData2.saccade.peakVelocityThreshold = repmat( ...
            classificationData2.saccade.peakVelocityThreshold, ...
            size(classificationData2.saccade.peakVelocity,1), ...
            size(classificationData2.saccade.peakVelocity,2));
        classificationData2.saccade.onsetVelocityThreshold = repmat( ...
            classificationData2.saccade.onsetVelocityThreshold, ...
            size(classificationData2.saccade.peakVelocity,1), ...
            size(classificationData2.saccade.peakVelocity,2));
        tbl_sac2 = struct2table(classificationData2.saccade);
        tbl_sac2.eye  = repmat(run2,height(tbl_sac2),1);
        tbl_sac2.run  = ones(height(tbl_sac2),1)+1;
        % adjust the indices
        tbl_sac2.on  = tbl_sac2.on  + idx_break - 1;
        tbl_sac2.off = tbl_sac2.off + idx_break - 1;
    end
end

% combine both runs
if exist('tbl_sac2','var') && exist('tbl_sac1','var')
    tbl_sac = [tbl_sac1; tbl_sac2];
elseif exist('tbl_sac1','var')
    tbl_sac = tbl_sac1;
elseif exist('tbl_sac2','var')
    tbl_sac = tbl_sac2;
end

%% add trial information for on and off to the event tables

% add an index row to the data table
tbl.on  = (1:height(tbl)).';
tbl.off = (1:height(tbl)).';

% add event info to fixations
cols    = ["trialNo","trialPic","trialVid"];
tbl_fix = join(tbl_fix,tbl(:,["on",cols]));
newNames = append("on_",cols);
tbl_fix = renamevars(tbl_fix,cols,newNames);
tbl_fix = join(tbl_fix,tbl(:,["off", cols]));
newNames = append("off_",cols);
tbl_fix = renamevars(tbl_fix,cols,newNames);

% add event info to saccades
cols    = ["trialNo","trialPic","trialVid","xPixel","yPixel"];
tbl_sac = join(tbl_sac,tbl(:,["on",cols]));
tbl_sac.xPixel = tbl_sac.xPixel + ETparams.screen.resolution(1)/2 - ETparams.screen.dataCenter(1);
tbl_sac.yPixel = tbl_sac.yPixel + ETparams.screen.resolution(2)/2 - ETparams.screen.dataCenter(2);
newNames = append("on_",cols);
tbl_sac = renamevars(tbl_sac,cols,newNames);
tbl_sac = join(tbl_sac,tbl(:,["off", cols]));
tbl_sac.xPixel = tbl_sac.xPixel + ETparams.screen.resolution(1)/2 - ETparams.screen.dataCenter(1);
tbl_sac.yPixel = tbl_sac.yPixel + ETparams.screen.resolution(2)/2 - ETparams.screen.dataCenter(2);
newNames = append("off_",cols);
tbl_sac = renamevars(tbl_sac,cols,newNames);

%% save data to disk

% save event tables for further analyses
writetable(tbl_sac, [dir_path filesep 'PESI-ET-' subID '_saccades.csv']);
writetable(tbl_fix, [dir_path filesep 'PESI-ET-' subID '_fixations.csv']);

end