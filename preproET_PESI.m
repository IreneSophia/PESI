% This function preprocesses eye tracking data for the PESI task collected
% with a LiveTrack Lightning Eye Tracker. It takes the filename of the csv
% and the path of the file as input. All data is saved in the same folder
% as the input file. 
% 
% Detection of events (blinks, saccades, glissades and fixations) is based
% on NYSTRÖM & HOLMQVIST (2010).
%
% (c) Irene Sophia Plank 10planki@gmail.com

function preproET_PESI(filename, dir_path)

%% read in data and calculate values

% get subject ID from the filename
subID = convertStringsToChars(extractBefore(filename,"_"));
fprintf('\nNow processing subject %s.\n', extractAfter(subID,'ET-'));

% set options for reading in the data
opts = delimitedTextImportOptions("NumVariables", 11);
opts.DataLines = [2, Inf];
opts.Delimiter = ",";
opts.VariableNames = ["timestamp", "trigger", "leftScreenX", "leftScreenY", "rightScreenX", "rightScreenY", "leftPupilMajorAxis", "leftPupilMinorAxis", "rightPupilMajorAxis", "rightPupilMinorAxis", "comment"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

tbl = readtable([dir_path filesep filename], opts); 

%% add trial information

% find trial indices
idx = find(extractBefore(tbl.comment,4) == "pic");

% find the break between runs
idx_break = find(strcmp(tbl.comment,"Comment"), 1);

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

% check if there are 64 trials
trls = unique(tbl.trialNo);
if sum(~isnan(trls)) ~= 64
    warning("The dataset %s only has %d trials!", subID, sum(~isnan(trls)))
end

%% classification of events

% generate parameters for NH2010 classification code.
ETparams = defaultParameters;
ETparams.screen.resolution              = [1920   1080]; % screen resolution in pixel
ETparams.screen.size                    = [0.533 0.300]; % screen size in m
ETparams.screen.viewingDist             = 0.57;          % viewing distance in m
ETparams.screen.dataCenter              = [0 0];         % center of screen has these coordinates in data
ETparams.screen.subjectStraightAhead    = [0 0];         % specify the screen coordinate that is straight ahead of the subject. Just specify the middle of the screen unless its important to you to get this very accurate!

% do the classification for the right eye
tbl.xPixel = tbl.rightScreenX*(ETparams.screen.resolution(1)/(ETparams.screen.size(1)*1000));
tbl.yPixel = tbl.rightScreenY*(ETparams.screen.resolution(2)/(ETparams.screen.size(2)*1000));
tbl.pupilDiameter = mean([tbl.rightPupilMajorAxis,tbl.rightPupilMinorAxis],2);
% run the NH2010 classifier code on full data set
[classificationDataR,ETparamsR]   = runNH2010Classification(...
    tbl.xPixel,tbl.yPixel,tbl.pupilDiameter,ETparams);
% merge glissades with saccades
classificationDataR = mergeSaccadesAndGlissades(classificationDataR);
if isfield(classificationDataR,'glissade')
    classificationDataR = rmfield(classificationDataR,'glissade');    
end

% do the classification for the left eye
tbl.xPixel = tbl.leftScreenX*(ETparams.screen.resolution(1)/(ETparams.screen.size(1)*1000));
tbl.yPixel = tbl.leftScreenY*(ETparams.screen.resolution(2)/(ETparams.screen.size(2)*1000));
tbl.pupilDiameter = mean([tbl.leftPupilMajorAxis,tbl.leftPupilMinorAxis],2);
% run the NH2010 classifier code on full data set
[classificationDataL,ETparamsL]   = runNH2010Classification(...
    tbl.xPixel,tbl.yPixel,tbl.pupilDiameter,ETparams);
% merge glissades with saccades
classificationDataL = mergeSaccadesAndGlissades(classificationDataL);
if isfield(classificationDataL,'glissade')
    classificationDataL = rmfield(classificationDataL,'glissade');    
end

%% create output tables

% fixations
fn = fieldnames(classificationDataR.fixation);
for k = 1:numel(fn)
    if size(classificationDataR.fixation.(fn{k}),1) < size(classificationDataR.fixation.(fn{k}),2)
        classificationDataR.fixation.(fn{k}) = classificationDataR.fixation.(fn{k}).';
    end
end
tbl_fixR = struct2table(classificationDataR.fixation);
fn = fieldnames(classificationDataL.fixation);
for k = 1:numel(fn)
    if size(classificationDataL.fixation.(fn{k}),1) < size(classificationDataL.fixation.(fn{k}),2)
        classificationDataL.fixation.(fn{k}) = classificationDataL.fixation.(fn{k}).';
    end
end
tbl_fixL = struct2table(classificationDataL.fixation);

% combine both eyes
tbl_fixR.side = repmat('R',height(tbl_fixR),1);
tbl_fixL.side = repmat('L',height(tbl_fixL),1);
if height(tbl_fixR) > 1 && height(tbl_fixL) > 1
    tbl_fix = [tbl_fixL; tbl_fixR];
elseif height(tbl_fixR) > 1
    tbl_fix = tbl_fixR;
else
    tbl_fix = tbl_fixL;
end

% saccades
fn = fieldnames(classificationDataR.saccade);
for k = 1:numel(fn)
    if size(classificationDataR.saccade.(fn{k}),1) < size(classificationDataR.saccade.(fn{k}),2)
        classificationDataR.saccade.(fn{k}) = classificationDataR.saccade.(fn{k}).';
    end
end
n_sac = size(classificationDataR.saccade.on);
if n_sac > 0
    classificationDataR.saccade.offsetVelocityThreshold = ...
        classificationDataR.saccade.offsetVelocityThreshold(1:n_sac);
    classificationDataR.saccade.peakVelocityThreshold = repmat( ...
        classificationDataR.saccade.peakVelocityThreshold, ...
        size(classificationDataR.saccade.peakVelocity,1), ...
        size(classificationDataR.saccade.peakVelocity,2));
    classificationDataR.saccade.onsetVelocityThreshold = repmat( ...
        classificationDataR.saccade.onsetVelocityThreshold, ...
        size(classificationDataR.saccade.peakVelocity,1), ...
        size(classificationDataR.saccade.peakVelocity,2));
    tbl_sacR = struct2table(classificationDataR.saccade);
    tbl_sacR.side = repmat('R',height(tbl_sacR),1);
end
fn = fieldnames(classificationDataL.saccade);
for k = 1:numel(fn)
    if size(classificationDataL.saccade.(fn{k}),1) < size(classificationDataL.saccade.(fn{k}),2)
        classificationDataL.saccade.(fn{k}) = classificationDataL.saccade.(fn{k}).';
    end
end
n_sac = size(classificationDataL.saccade.on);
if n_sac > 0
    classificationDataL.saccade.offsetVelocityThreshold = ...
        classificationDataL.saccade.offsetVelocityThreshold(1:n_sac);
    classificationDataL.saccade.peakVelocityThreshold = repmat( ...
        classificationDataL.saccade.peakVelocityThreshold, ...
        size(classificationDataL.saccade.peakVelocity,1), ...
        size(classificationDataL.saccade.peakVelocity,2));
    classificationDataL.saccade.onsetVelocityThreshold = repmat( ...
        classificationDataL.saccade.onsetVelocityThreshold, ...
        size(classificationDataL.saccade.peakVelocity,1), ...
        size(classificationDataL.saccade.peakVelocity,2));
    tbl_sacL = struct2table(classificationDataL.saccade);
    tbl_sacL.side = repmat('L',height(tbl_sacL),1);
end

% combine both eyes
if exist('tbl_sacL','var') && exist('tbl_sacR','var')
    tbl_sac = [tbl_sacL; tbl_sacR];
elseif exist('tbl_sacR','var')
    tbl_sac = tbl_sacR;
elseif exist('tbl_sacL','var')
    tbl_sac = tbl_sacL;
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

% save data structures and classification parameters to .mat file
save([dir_path filesep subID '_prepro.mat'], ...
    'classificationDataR', 'classificationDataL', ...
    'ETparamsR', 'ETparamsL');

% save event tables for further analyses
writetable(tbl_sac, [dir_path filesep subID '_saccades.csv']);
writetable(tbl_fix, [dir_path filesep subID '_fixations.csv']);

end