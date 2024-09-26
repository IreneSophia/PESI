
% This function presents the perception of nonverbal social interaction
% task from the PESI project. 
% (c) Irene Sophia Plank, irene.plank@med.uni-muenchen.de
% Per trial 300 pictures are presented, 30 per second. The video shows an
% a dyadic nonverbal social interaction of either a heterogeneous (one
% autistic and one non-autistic interaction partner) or a homogeneous
% non-autistic dyad. After watching a video, participants are asked to rate
% how "angenehm" they found the interaction. They can give their rating by 
% using the key_left and key_right to select an option that
% they confirm by using the key_choose. There are 64 trials.
% This function takes two inputs: 
% * subID        :  a string array with the subjects PID
% * eyeTracking  :  0 or 1 to choose eye tracking or not
% The function needs Psychtoolbox to function properly. If eye tracking has
% been chosen, then a LiveTracking Eye Tracker has to be connected and the
% LiveTrackToolbox for MATLAB has to be installed. The function is meant to
% be used without an external monitor. Using a second monitor can seriously
% mess up the timing. 
% The function continually saves behavioural data as well as eye tracking
% data if that option is chosen. Both files will be placed in the "Data"
% folder. 
function PESI_task_afterbreak

% Get all relevant inputs. 
inVar = inputdlg({'Enter PID: ', 'Eye Tracking? 0 = no, 1 = yes', 'Which run? 1 or 2'}, 'Input variables', [1 45]);
subID = convertCharsToStrings(inVar{1});
eyeTracking = str2double(inVar{2});
run = str2double(inVar{3});

% Get the path of this function. 
path_src = fileparts(mfilename("fullpath")); 
path_dat = [path_src filesep 'dataPESI' filesep];

% Clear the screen
sca;
close all;

% Initialise some settings
fx    = 40;     % size of the size of the arms of our fixation cross
fxdur = 0.05;    % duration of the fixation cross in seconds
maxrs = 4;      % maximum response time 

% Which keys are used for what
key_left   = '4';
key_right  = '6';
key_choose = '8';

% How much to shift the pictures up. 
shift = 200;

% Open a csv file into which you can write information
fid = fopen(path_dat + "PESI-BV-" + subID + "_" + datestr(datetime(),'yyyymmdd-HHMM') + "_2.csv", 'w');
fprintf(fid, 'subID,run,trl,video,dyad,sync,dur,rating,confirmed,moved,rt\n');

% Add eye tracking stuff, if eyeTracking is set to 1. 
if eyeTracking
    % Initialise LiveTrack
    crsLiveTrackInit;
    % Open a data file to write the data to.
    crsLiveTrackSetDataFilename(char(path_dat + "PESI-ET-" + subID + "_" + datestr(datetime(),'yyyymmdd-HHMM') + "_2.csv"));
end

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% This use of the subfunction 'UnifyKeyNames' within KbName()
% sets the names of the keys to be the same across operating systems
% (This is useful for making our experiment compatible across computers):
KbName('UnifyKeyNames');

% Load the list of stimuli.
load([path_src '\PESI_list.mat'],'vids')

% As before we start a 'try' block, in which we watch out for errors.
try


%% First run.
    
    % Randomise the order of the videos.
    vids{run} = Shuffle(vids{run},2);
    
    % Get number of trials. 
    ntrials = length(vids{runs(1)});
    
    % Get the screen numbers. This gives us a number for each of the screens
    % attached to our computer.
    % For help see: Screen Screens?
    screens = Screen('Screens');
    
    % Adjust tests of the system:
    Screen('Preference','SkipSyncTests', 0);
    Screen('Preference','SyncTestSettings', 0.0025);
    
    % Draw we select the maximum of these numbers. So in a situation where we
    % have two screens attached to our monitor we will draw to the external
    % screen. When only one screen is attached to the monitor we will draw to
    % this.
    % For help see: help max
    screenNumber = max(screens);
    
    % Define white and black.
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    
    % And the function ListenChar(), with the single number input 2,
    % stops the keyboard from sending text to the Matlab window.
    ListenChar(2);
    % To switch the keyboard input back on later we will use ListenChar(1).

    % Open an on screen window and color it black
    % For help see: Screen OpenWindow?
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

    % Hide the mouse cursor
    HideCursor(window);
    
    % Get the centre coordinate of the window in pixels
    % For help see: help RectCenter
    [xCenter, yCenter] = RectCenter(windowRect);

    % Query the frame duration
    ifi = Screen('GetFlipInterval', window);

    % Set text size.
    Screen('TextSize', window, 40);

    % Set up alpha-blending for smooth (anti-aliased) lines
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Here we set the size of the arms of our fixation cross
    fixCrossDimPix = fx;
    
    % Now we set the coordinates (these are all relative to zero we will let
    % the drawing routine center the cross in the center of our monitor for us)
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    
    % Set the line width for our fixation cross
    lineWidthPix = round(fx/10);
    
    % Draw start text.
    DrawFormattedText(window, sprintf('Drücken Sie die Taste %s, um zu starten.', key_choose),...
        'center', yCenter-shift, white);
    
    % Flip to the screen
    Screen('Flip', window);
    
    % Wait for the experiment to be started or aborted.
    decision = 0;
    while decision == 0
        [~,~,keys] = KbCheck;
        key = KbName(keys);
        if strcmp(key,'ESCAPE')
            % If it was, we generate an error, which will stop our script.
            % This will also send us to the catch section below,
            % where we close the screen and re-enable the keyboard for Matlab.
            error('Experiment aborted.')
        elseif strcmp(key,key_choose)
            decision = 1;
        end
    end

    if eyeTracking
        % Start streaming calibrated results
        crsLiveTrackSetResultsTypeCalibrated;
        % Start tracking
        crsLiveTrackStartTracking;
    end
    
    % Go through the trials
    for j = 1:ntrials
    
        % Draw the fixation cross in grey, set it to the center of our screen and
        % set good quality antialiasing
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter-shift], 2);

        % Flip the fixation cross to the screen
        Screen('Flip', window);
        WaitSecs(fxdur-ifi);

        % Determine which video is loaded. 
        video = vids{runs(1)}{j,1};
        dyad  = vids{runs(1)}{j,2};
        sync  = vids{runs(1)}{j,3};

        % Load all pics making up this video.
        pic_files = dir([path_src '\Stimuli_contrast\' video filesep '*.jpg']);
        pics = nan(length(pic_files),1);
        for i = 1:length(pic_files)
            pic = imread([pic_files(i).folder filesep pic_files(i).name]);
            pics(i) = Screen('MakeTexture', window, pic);
        end
        pic_width  = size(pic,2)/2;
        pic_height = size(pic,1)/2;
        
        % Draw the pictures to the screen. 
        t_start = GetSecs;
        for i = 1:300
            Screen('DrawTexture', window, pics(i), [], ... % we want the images to be twice their normal size
                [xCenter-pic_width yCenter-pic_height-shift ...
                xCenter+pic_width yCenter+pic_height-shift]);
            % Flip the pic to the screen
            Screen('Flip', window);
            if eyeTracking
                % Add a comment/trigger to the eye tracking data. 
                crsLiveTrackSetDataComment(sprintf('pic_%s_%i_%i',...
                    video,j,i));
            end
            Screen('Close',pics(i))
            WaitSecs(0.025);
            % Add a check for pressed keys and abort if ESC was pressed. 
            [~,~,keys] = KbCheck;
            key = KbName(keys);
            if strcmp(key,'ESCAPE')
            
                % If it was, we generate an error, which will stop our script.
                % This will also send us to the catch section below,
                % where we close the screen and re-enable the keyboard for Matlab.
                error('Experiment aborted.')
            end
            
        end
        t_stop = GetSecs;
        dur = t_stop - t_start;

        % Now we present the rating scale.
        prompt   = 'Wie angenehm fanden Sie die Interaktion?';
        extremes = {'gar nicht', 'sehr'};
        before   = GetSecs;
        [rating, confirmed, moved] = rating_scale(prompt, extremes, ...
                window, windowRect, white, 1000, maxrs, 10, ...
                key_left, key_right, key_choose);
        rt = GetSecs - before;

        % Log all the information for this trial
        fprintf(fid, '%s,%i,%i,%s,%s,%s,%.4f,%.2f,%i,%i,%.4f\n',...
            subID,runs(1),j,video,dyad,sync,dur,rating,confirmed,moved,rt);

    end

    % If we encounter an error...
catch my_error

    % Close all open objects
    Screen('Close');

    % Show the mouse cursor
    if exist('window', 'var')
        ShowCursor(window);
    end
    
    % Clear the screen (so we can see what we are doing).
    sca;
    
    % In addition, re-enable keyboard input (so we can type).
    ListenChar(1);

    % Close the open csv file 
    fclose(fid);

    % Stop eye tracking. 
    if eyeTracking
        crsLiveTrackStopTracking;
        crsLiveTrackCloseDataFile;
        crsLiveTrackClose;
    end
    
    % Tell us what the error was.
    rethrow(my_error)
    
end

% At the end, clear the screen and re-enable the keyboard.
Screen('Close');
ShowCursor(window);
sca;
ListenChar(1);
fclose(fid);
if eyeTracking
    crsLiveTrackStopTracking;
    crsLiveTrackCloseDataFile;
    crsLiveTrackClose;
end

end
