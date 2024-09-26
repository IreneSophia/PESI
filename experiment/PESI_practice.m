
% This function presents the practice for the PESI. 
% (c) Irene Sophia Plank, irene.plank@med.uni-muenchen.de
% It takes no input and produces no data. There is only 1 practice
% video, however, it can be repeated until the participant has understood
% the task. 
function PESI_practice 

% Get the path of this function. 
path = fileparts(mfilename("fullpath")); 

% Clear the screen
sca;
close all;

% Initialise some settings
fx    = 40;     % size of the size of the arms of our fixation cross
fxdur = 0.05;    % duration of the fixation cross in seconds
maxrs = 8;      % maximum response time  

% Which keys are used for what
key_left   = '4';
key_right  = '6';
key_choose = '8';

% How much to shift the pictures up. 
shift = 200;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% This use of the subfunction 'UnifyKeyNames' within KbName()
% sets the names of the keys to be the same across operating systems
% (This is useful for making our experiment compatible across computers):
KbName('UnifyKeyNames');

% Create stimulus order by starting of with list of videos and assuming
% that their order violates our conditions.
video = 'PESI-prac_D13_24_00001920';

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
% For help see: Screen Screens?
screens = Screen('Screens');

% Adjust tests of the system:
Screen('Preference','SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);
Screen('Preference','SuppressAllWarnings', 1);

% Draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen. When only one screen is attached to the monitor we will draw to
% this.
% For help see: help max
screenNumber = max(screens);

% Define white and black.
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);

% And the function ListenChar(), with the single number input 2,
% stops the keyboard from sending text to the Matlab window.
ListenChar(2);
% To switch the keyboard input back on later we will use ListenChar(1).

% As before we start a 'try' block, in which we watch out for errors.
try

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

    % Draw instructions.
    str =   "In dieser Aufgabe sehen Sie Videos von Interaktionen zwischen jeweils zwei Menschen.\n" + ...
            "Alle Menschen kommen dabei öfters vor.\n" + ... 
            "Sie sehen nur die Umrisse der Menschen und die Videos sind stumm.\n\n" + ...
	        "Nach jedem Video werden Sie gebeten,\n" + ...
            "auf einer Skala anzugeben, wie angenehm Sie die Interaktion fanden.\n\n" + ...
			"Mit der Taste " + convertCharsToStrings(key_left) + " können Sie den Regler nach links verschieben,\n" + ...
			"mit der Taste " + convertCharsToStrings(key_right) + " nach rechts\n" + ...
            "und mit der Taste " + convertCharsToStrings(key_choose) + " bestätigen Sie Ihre Auswahl.\n\n" + ...
			"Bitte wählen Sie zügig aus und bestätigen Sie jede Auswahl.\n" + ...
            "Sie haben für jede Auswahl " + string(maxrs) + " Sekunden Zeit.\n\n" + ...
			"Drücken Sie jetzt die Taste " + convertCharsToStrings(key_choose) + ", um die Übung zu starten!";
    chr = convertStringsToChars(str);
    DrawFormattedText(window, chr,...
        'center', 100, white);
    
    % Flip to the screen
    Screen('Flip', window);
    % screenshot = Screen('GetImage', window);
    % imwrite(screenshot, 'PESI_screenshot-intro.png');
    
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
    
    % Set the line width for our fixation cross
    lineWidthPix = round(fx/10);
    
    % Draw the fixation cross in grey, set it to the center of our screen and
    % set good quality antialiasing
    Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter-shift], 2);

    % Flip the fixation cross to the screen
    Screen('Flip', window);
    WaitSecs(fxdur-ifi);
    % screenshot = Screen('GetImage', window);
    % imwrite(screenshot, 'PESI_screenshot-fix.png');

    % Load all pics making up this video.
    pic_files = dir([path '\Stimuli_contrast\' video filesep '*.jpg']);
    pics = nan(length(pic_files),1);
    for i = 1:length(pic_files)
        pic = imread([pic_files(i).folder filesep pic_files(i).name]);
        pics(i) = Screen('MakeTexture', window, pic);
    end
    pic_width  = size(pic,2)/2; 
    pic_height = size(pic,1)/2;
    
    % Draw the pictures to the screen. 
    for i = 1:length(pics)
        Screen('DrawTexture', window, pics(i), [], ... 
            [xCenter-pic_width yCenter-pic_height-shift ...
            xCenter+pic_width yCenter+pic_height-shift]);
        % Flip the pic to the screen
        Screen('Flip', window);
        % screenshot = Screen('GetImage', window);
        % imwrite(screenshot, 'PESI_screenshot.png');
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

    % Now we present the rating scale.
    prompt   = 'Wie angenehm fanden Sie die Interaktion?';
    extremes = {'gar nicht', 'sehr'};
    rating_scale(prompt, extremes, ...
            window, windowRect, white, 1000, maxrs, 10, ...
            key_left, key_right, key_choose);

    % screenshot = Screen('GetImage', window);
    % imwrite(screenshot, 'PESI_screenshot-rating.png');
    
    % If we encounter an error...
catch my_error

    % Close all open objects
    Screen('Close');

    % Show the mouse cursor
    ShowCursor(window);
    
    % Clear the screen (so we can see what we are doing).
    sca;
    
    % In addition, re-enable keyboard input (so we can type).
    ListenChar(1);
    
    % Tell us what the error was.
    rethrow(my_error)
    
end

% At the end, clear the screen and re-enable the keyboard.
Screen('Close');
ShowCursor(window);
sca;
ListenChar(1);
end
