% This function creates a rating scale with a slider using Psychtoolbox. 
% It has the following inputs: 
%       prompt (char)     : text above the rating scale
%       extremes (cell)   : cell array containing character arrays for the 
%                           extremes of the rating scale, left then right
%       w (num)           : PTB window where it should be drawn
%       winRect (num)     : rectangle of the window (1x4 matrix)
%       col (num)         : colour of all the objects
%       length (num)      : length of the slider in pixels
%       maxdur (num)      : maximal response time in seconds
%       pxper (num)       : how many pixels the slider moves per key
%       left (char)       : key to move the slider left
%       right(char)       : key to move the slider right
%       confirm (char)    : key to confirm the choice
%
% One output is created: 
%       rating (num)      : rating in percent
%
% (C) Irene Sophia Plank, 10planki@gmail.com
function [rating, confirmed, moved] = rating_scale(prompt, extremes, w, winRect, col, length,...
    maxdur, pxper, left, right, confirm)

moved     = 0;
confirmed = 0;

% This adjusts the sensitivity depending on the flip interval.
ifi = Screen('GetFlipInterval', w); 
waitframes = 1;

% Get middle points and half of the length of the rating scale.
[xCenter, yCenter] = RectCenter(winRect);
LineX = xCenter; 
LineY = yCenter;
half  = length/2;
    
% Determine size of the slider.
baseRect = [0 0 0.01*length 0.06*length]; 

% Get start point.
t_start = GetSecs;
t_now   = t_start;

% Available keys.
escapeKey = KbName('ESCAPE');
conKey    = KbName(confirm);
leftKey   = KbName(left);
rightKey  = KbName(right);

while (t_now - t_start) < maxdur

    % Check whether a key was pressed.
    [ ~, ~, keyCode ] = KbCheck;
    key = find(keyCode);

    % What happens depends on the key that is pressed.
    if key == escapeKey
        break
    elseif key == leftKey
        LineX = LineX - pxper;
        moved = 1;
    elseif key == rightKey
        LineX = LineX + pxper;
        moved = 1;
    elseif key == conKey
        rating = ((LineX - xCenter) + half)/(length/100); % for a rating of between 0 and 100. Tweak this as necessary.
        confirmed = 1;
        break;
    end

    % If we are outside of the line, it is reset to the last possible
    % point.
    if LineX < (xCenter - half)
        LineX = (xCenter - half);
    elseif LineX > (xCenter + half)
        LineX = (xCenter + half);
    end
    if LineY < 0
        LineY = 0;
    elseif LineY > (yCenter+10)
        LineY = (yCenter+10);
    end

    % Calculate the current rating.
    rating = ((LineX - xCenter) + half)/(length/100);

    % Draw the slider. 
    centeredRect = CenterRectOnPointd(baseRect, LineX, LineY);

    % Draw the prompt above the rating scale.
    DrawFormattedText(w, prompt ,'center', (yCenter-100), col, [],[],[],5);
    
    % Draw the lines.
    Screen('DrawLine', w,  col, (xCenter+half), (yCenter),(xCenter-half), (yCenter), 1);
    Screen('DrawLine', w,  col, (xCenter+half), (yCenter+0.03*length), (xCenter+half), (yCenter-0.03*length), 1);
    Screen('DrawLine', w,  col, (xCenter-half), (yCenter+0.03*length), (xCenter-half), (yCenter-0.03*length), 1);
    
    % Add descriptions for the extremes.
    Screen('DrawText', w, extremes{1}, (xCenter-half), (yCenter+40),  col);
    Screen('DrawText', w, extremes{2} , (xCenter+half) , (yCenter+40), col);

    % Draw the rectangle to the screen. 
    Screen('FillRect', w, col, centeredRect);

    t_now = Screen('Flip', w, t_now + (waitframes - 0.5) *  ifi);

end

end