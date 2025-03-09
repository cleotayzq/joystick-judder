% Clear the workspace and command window
clc; clearvars;

% Check for connected game controllers
numGamepads = Gamepad('GetNumGamepads');
if numGamepads < 1
    error('No gamepad detected! Connect a controller and try again.');
end

gamepadIndex = 1; % Default to first controller

% Get button & axis count
numButtons = Gamepad('GetNumButtons', gamepadIndex);
numAxes = Gamepad('GetNumAxes', gamepadIndex);

fprintf('Controller detected!\n');
fprintf('Your controller has %d buttons and %d axes.\n', numButtons, numAxes);
fprintf('Press any button or move a joystick to test. Press Q to quit.\n\n');

% Button names (Matches DualSense layout)
buttonNames = { 'Square', 'X', 'Circle', 'Triangle', ... % 1-4
                'L1', 'R1', 'L2', 'R2', ...             % 5-8
                'Share', 'Options', 'L3', 'R3', ...      % 9-12
                'PS', 'Touchpad', 'Mute'};              % 13-15

if length(buttonNames) ~= numButtons
    warning('Detected %d buttons, but expected 15. Some buttons may be missing.', numButtons);
end

% Axis mappings
axisNames = {'Left Stick X', 'Left Stick Y', 'Right Stick X', 'Right Stick Y', ...
             'L2 Press', 'R2 Press'}; % Axes 5-6 are L2/R2 pressure

% Deadzone & spam prevention
deadzone = 500; % Prevents tiny flickers
idleAxisValues = zeros(1, numAxes);
prevAxisValues = zeros(1, numAxes); % Track previous axis values

% Calibrate idle axis values
for i = 1:numAxes
    idleAxisValues(i) = Gamepad('GetAxis', gamepadIndex, i);
end

fprintf('Idle calibration complete! Ignoring values close to:\n');
disp(idleAxisValues);

% Boilerplate
ListenChar(2);
KbName('UnifyKeyNames');
quitKey = KbName('q');

while true
    % --- Quit Check ---
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(quitKey)
        break;
    end

    % --- Button Press Detection ---
    for i = 1:numButtons
        if Gamepad('GetButton', gamepadIndex, i)
            if i <= length(buttonNames)
                fprintf('Button %d (%s) pressed\n', i, buttonNames{i});
            else
                fprintf('Button %d (UNKNOWN) pressed\n', i);
            end
            pause(0.2); % Prevent spam
        end
    end

    % --- Axis Movement Detection ---
    allNeutral = true;
    for i = 1:numAxes
        axisValue = Gamepad('GetAxis', gamepadIndex, i);
        adjustedValue = axisValue - idleAxisValues(i); % Remove baseline drift

        % Only detect real movement and avoid repeated printing
        if abs(adjustedValue) > deadzone && abs(adjustedValue - prevAxisValues(i)) > deadzone
            if i <= length(axisNames)
                fprintf('Axis %d (%s) moved: %.2f\n', i, axisNames{i}, adjustedValue);
            else
                fprintf('Axis %d (UNKNOWN) moved: %.2f\n', i, adjustedValue);
            end
            prevAxisValues(i) = adjustedValue; % Update previous value
            allNeutral = false;
        end
    end

    % --- Reset Idle Values After Letting Go ---
    if allNeutral
        for i = 1:numAxes
            idleAxisValues(i) = Gamepad('GetAxis', gamepadIndex, i);
            prevAxisValues(i) = 0; % Reset previous values
        end
    end

    % Small delay to prevent high CPU usage
    WaitSecs(0.05);
end

% Restore keyboard input
ListenChar(0);
fprintf('Exited controller test.\n');