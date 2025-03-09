% Clear the screen and workspace
sca; close all; clearvars;

% Psychtoolbox setup (low resource usage)
PsychDefaultSetup(1);

% Fix potential PTB issues (skip sync tests)
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'ConserveVRAM', 64);

% Open a PTB window
[window, windowRect] = Screen('OpenWindow', max(Screen('Screens')), 0);
Screen('TextSize', window, 50);

% Boilerplate setup
ListenChar(2);
GetSecs;
KbName('UnifyKeyNames');

% Get the number of connected game controllers
numGamepads = Gamepad('GetNumGamepads');
if numGamepads < 1
    error('No gamepad detected. Connect a controller and try again.');
end

% Use the first detected controller
gamepadIndex = 1;

% Define button mappings for DualSense
actionButtons = {'Square', 'X', 'Circle', 'Triangle'}; % Face buttons
actionButtonIDs = [1, 2, 3, 4];

otherButtons = {'L1', 'R1', 'L2', 'R2', 'Share', 'Options', 'Left Stick Press', 'Right Stick Press', 'PS', 'Touchpad', 'Mute'};
otherButtonIDs = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

% Joystick axis mappings
leftStickAxes = [1, 2]; % Left Stick X, Y
rightStickAxes = [3, 4]; % Right Stick X, Y
L2TriggerAxis = 5; % L2 button pressure
R2TriggerAxis = 6; % R2 button pressure

% Deadzone and scaling
deadzone = 5; % relative to 100
maxJoystickValue = 32768;
scaleFactor = 100 / maxJoystickValue;

% Define 'q' as quit keys
quitKey = KbName('q');

while true
    % Check if 'q' button is pressed to exit
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(quitKey)
        break;
    end

    % --- Action Button Detection ---
    actionPressed = 'None';
    for i = 1:length(actionButtons)
        if Gamepad('GetButton', gamepadIndex, actionButtonIDs(i))
            actionPressed = actionButtons{i};
            break;
        end
    end

    % --- Other Buttons Detection ---
    otherPressed = 'None';
    for i = 1:length(otherButtons)
        if Gamepad('GetButton', gamepadIndex, otherButtonIDs(i))
            otherPressed = otherButtons{i};
            break;
        end
    end

    % --- Thumbstick Detection ---
    rawLeftX = Gamepad('GetAxis', gamepadIndex, leftStickAxes(1));
    rawLeftY = Gamepad('GetAxis', gamepadIndex, leftStickAxes(2));
    rawRightX = Gamepad('GetAxis', gamepadIndex, rightStickAxes(1));
    rawRightY = Gamepad('GetAxis', gamepadIndex, rightStickAxes(2));
    rawL2 = Gamepad('GetAxis', gamepadIndex, L2TriggerAxis);
    rawR2 = Gamepad('GetAxis', gamepadIndex, R2TriggerAxis);

    leftX = max(min(round(rawLeftX * scaleFactor), 100), -100);
    leftY = max(min(round(rawLeftY * scaleFactor), 100), -100);
    rightX = max(min(round(rawRightX * scaleFactor), 100), -100);
    rightY = max(min(round(rawRightY * scaleFactor), 100), -100);
    L2Press = max(min(round(rawL2 * scaleFactor), 100), 0);
    R2Press = max(min(round(rawR2 * scaleFactor), 100), 0);
    
    % Flip Y-axis values
    leftY = -leftY;
    rightY = -rightY;

    % Apply deadzone correction
    if abs(leftX) < deadzone, leftX = 0; end
    if abs(leftY) < deadzone, leftY = 0; end
    if abs(rightX) < deadzone, rightX = 0; end
    if abs(rightY) < deadzone, rightY = 0; end

    % Format stick output
    leftStickMsg = sprintf('Left Stick: (%d, %d)', leftX, leftY);
    rightStickMsg = sprintf('Right Stick: (%d, %d)', rightX, rightY);
    L2Msg = sprintf('L2 Press: %d', L2Press);
    R2Msg = sprintf('R2 Press: %d', R2Press);

    % --- Display Output on Screen ---
    message = sprintf(...
        'Action: %s\nOther buttons: %s\n%s\n%s\n%s\n%s\n\n(D-pad not detected on this system)\nPress Q to quit.', ...
        actionPressed, otherPressed, leftStickMsg, rightStickMsg, L2Msg, R2Msg);

    DrawFormattedText(window, message, 'center', 'center', 255);
    Screen('Flip', window);
end

% Close the PTB window
sca;