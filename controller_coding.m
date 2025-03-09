% Psychtoolbox setup (low resource usage)
PsychDefaultSetup(1);

% Fix PTB issues (skip sync tests)
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'ConserveVRAM', 64);

% Open a PTB window
screenNumber = max(Screen('Screens'));
[window, windowRect] = Screen('OpenWindow', screenNumber, 0);
Screen('TextSize', window, 50);

% Get inter-frame interval (ifi)
ifi = Screen('GetFlipInterval', window);

% Boilerplate setup
ListenChar(2);
GetSecs;
KbName('UnifyKeyNames');

% Get the number of connected game controllers
numGamepads = Gamepad('GetNumGamepads');
if numGamepads < 1
    error('No gamepad detected! Connect a controller and try again.');
end

gamepadIndex = 1;

% Define button mappings for DualSense
navigationButtons = {'L2', 'R2'};
navigationButtonIDs = [7, 8];

actionButtons = {'Square', 'X', 'Circle', 'Triangle', 'L1', 'R1'};
actionButtonIDs = [1, 2, 3, 4, 5, 6];

optionsButtonID = 10; % Options button
psButtonID = 13; % PS Button (to quit)
quitKey = KbName('q'); % 'Q' key for quitting

% Playback rate settings
realTimeFPS = 25; % Real-time speed
maxPlaybackRate = 1.25; % How many times of real-time speed?
maxFPS = round(realTimeFPS * maxPlaybackRate); % Maximum playback speed
deadZone = 2; % Dead zone is relative to FPS

maxJoystickValue = 32768; % Joystick range
leftStickX = 1; % Left stick left/right for navigation

% Frame counter setup
numFrames = 250; % Set this to the total number of frames you have
FrameCounter = 1;
playbackRate = 0; % Default playback rate
paused = true; % Start in paused mode
framesPerUpdate = round(1 / (max(realTimeFPS, 1) * ifi)); % Prevent division by zero

% Initialize response array (empty responses)
frameResponses = strings(numFrames, 1); % Empty string array

% State tracking for single press detection
prevL2State = false;
prevR2State = false;

frameCounter = 0; % Frame counter for timing

% Main loop
while FrameCounter <= numFrames

    % --- Check if 'q' or PS button is pressed to exit ---
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(quitKey)
        break;
    end
    if Gamepad('GetButton', gamepadIndex, psButtonID)
        break;
    end

    % --- Options Button Handling (Help Menu) ---
    if Gamepad('GetButton', gamepadIndex, optionsButtonID)
        DrawFormattedText(window, 'Help Menu\n\n- R2: Next Frame\n- L2: Previous Frame\n- Left Stick: Adjust speed\n- Action Buttons: Record Response\n- Options: Help Menu\n- PS Button: Quit', 'center', 'center', 255);
        Screen('Flip', window);
        WaitSecs(2); % Display for 2 seconds
    end

    % --- Navigation Handling (Single Press for L2 / R2) ---
    currR2State = Gamepad('GetButton', gamepadIndex, navigationButtonIDs(2));
    currL2State = Gamepad('GetButton', gamepadIndex, navigationButtonIDs(1));

    if currR2State && ~prevR2State
        FrameCounter = min(numFrames, FrameCounter + 1);
    end
    if currL2State && ~prevL2State
        FrameCounter = max(1, FrameCounter - 1);
    end

    prevR2State = currR2State;
    prevL2State = currL2State;

    % --- Joystick Control for Playback ---
    rawLeftX = Gamepad('GetAxis', gamepadIndex, leftStickX);
    joystickX = round(maxFPS * rawLeftX / maxJoystickValue); % value scaled to max FPS

    % If joystick is within dead zone, pause playback
    if abs(joystickX) < deadZone
        paused = true;
        playbackRate = 0;
    else
        paused = false;
        playbackRate = joystickX;
    end

    % Update frames per update based on playback rate
    if playbackRate ~= 0
        framesPerUpdate = round(1 / (abs(playbackRate) * ifi)); % Use absolute value to avoid issues
    else
        framesPerUpdate = Inf; % Prevent division by zero
    end

    % --- Frame Counter Updates Based on IFI ---
    frameCounter = frameCounter + 1;
    if mod(frameCounter, framesPerUpdate) == 0
        FrameCounter = min(numFrames, max(1, FrameCounter + sign(playbackRate)));
    end

    % --- Response Button Handling (Detect Current Button Press) ---
    responsePressed = ""; % Default to empty string
    for i = 1:length(actionButtons)
        if Gamepad('GetButton', gamepadIndex, actionButtonIDs(i))
            responsePressed = actionButtons{i}; % Store response
            break; % Only one response allowed at a time
        end
    end

    % If a button is pressed, store the response for the current frame
    if responsePressed ~= ""
        frameResponses(FrameCounter) = responsePressed;
    end

    % Get recorded response for the current frame
    recordedResponse = frameResponses(FrameCounter);
    if recordedResponse == "" % If no response recorded, show 'None'
        recordedResponse = "None";
    end

    % --- Display Output on Screen ---
    message = sprintf(...
        'Frame: %d / %d\nPlayback: %d FPS\nPaused: %s\n\nCurrent Response: %s\nRecorded Response for this Frame: %s', ...
        FrameCounter, numFrames, playbackRate, string(paused), responsePressed, recordedResponse);

    DrawFormattedText(window, message, 'center', 'center', 255);
    Screen('Flip', window);
end

% Convert responses to table (Fixes length mismatch)
frameNumbers = (1:numFrames)';
frameResponses = frameResponses(1:numFrames); % Ensure the length is correct
frameResponsesTable = table(frameNumbers, frameResponses, 'VariableNames', {'FrameNumber', 'Response'});

% Save as CSV
writetable(frameResponsesTable, 'responses.csv');

% Close the PTB window
sca;

disp('Responses saved to responses.csv');