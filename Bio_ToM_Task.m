%%% Bio Theory of Mind Task  %%%
%%% Script by Branden Bio    %%%
%%% Written 01/19/2017       %%%
%%% Updated 05/07/2019       %%%
%%% Department of Psychology %%%
%%% Princeton University     %%%

sca;
close all;
clearvars;
beep off;
reset(RandStream.getGlobalStream,sum(100*clock));
%Screen('Preference', 'SkipSyncTests', 1);

% Default settings for Psychtoolbox
PsychDefaultSetup(2);

KbName('UnifyKeyNames');

Priority(1);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Recording subj info
subjectID = input('subject ID: ');
output.subjectInfo.subjectID = subjectID;
filename = sprintf('ToM_%s_results.mat',subjectID);
filenameV = sprintf('ToM_%s_vars.mat',subjectID);
foo = dir(['raw_data\\' filename]);
index = 1;
while ~isempty(foo)
    index = index + 1;
    filename = sprintf('ToM_%s_results_v%d.mat',subjectID,index);
    filenameV = sprintf('ToM_%s_vars_v%d.mat',subjectID,index);
    foo = dir(['raw_data\\' filename]);
end
mainPath = pwd;
sf_path = 'raw_data\\%s';
sfv_path = 'raw_data\\vars\\%s';
server_filename = sprintf(sf_path,filename);
server_filenameV = sprintf(sfv_path,filenameV);

% Options to run left and right handed individuals
% This controls user response buttons which change based on handedness
% If you only want to run right-handers, set handedness = 1 and comment out
% handedness input below
% Left-handed = 0, right-handed = 1
handedness = input('left [0] or right [1] handed?\n');
output.subjectInfo.handedness = handedness;

data.runDate = date;

% Timing variables
shortTime = 0.5;
longTime = 1;
responseTime = 1.5;
scan_start_buffer = 5;
runIns = input('View instructions?\n');
runPrac = input('Practice runs?\n');

try
% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the center coordinates of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Calculate pixels/cm
horizontal_pixels = screenXpixels;   % Width of screen in pixels
monitor_width = 58.7537; % Width of screen in cm
pixels_per_cm = horizontal_pixels/monitor_width;

% Distance from screen, also necessary for calculating stimulus size
screen_distance = 66; % Distance in cm

% Conversion from degrees to pixels
cm_per_degree = tand(1) * screen_distance;
pixels_per_degree = cm_per_degree * pixels_per_cm;

% Length in deg
BRDeg  = 3.1534;
IRDeg1 = 5.4028;
IRDeg2 = 4.6250;
CRDeg  = 1.2614;

% Translate to pix
BRLength  = BRDeg * pixels_per_degree;
IRLength1 = IRDeg1 * pixels_per_degree;
IRLength2 = IRDeg2 * pixels_per_degree;
CRLength  = CRDeg * pixels_per_degree;

% Rect arrays
baseRect = [0 0 BRLength BRLength];
initRect = [0 0 IRLength1 IRLength2];
circleRect = [0 0 CRLength CRLength];

% Screen positions of numbers
numYDeg_from_center = 8.8;
numY = yCenter - (numYDeg_from_center * pixels_per_degree);
num1XDeg_from_center = 10;
num1X = xCenter - (num1XDeg_from_center * pixels_per_degree);
num2XDeg_from_center = 9.5;
num2X = xCenter + (num2XDeg_from_center * pixels_per_degree);

% Screen positions of rectangles
squareXposDeg_from_center = 12;
squareXposPix_from_center = squareXposDeg_from_center * pixels_per_degree;
squareXpos = [(xCenter - squareXposPix_from_center) (xCenter + squareXposPix_from_center)];
squareYposDeg_from_center = 9;
squareYposPix_from_center = squareYposDeg_from_center * pixels_per_degree;
squareYpos = yCenter - squareYposPix_from_center;
numSqaures = length(squareXpos);

% Screen positions of images
imdist_from_horiz_center_deg = 3.25;
imdist_from_horiz_center_pixels = imdist_from_horiz_center_deg * pixels_per_degree;
im1X = xCenter - imdist_from_horiz_center_pixels;
im2X = xCenter + imdist_from_horiz_center_pixels;

% Screen positions of images
dist_above_vert_center_deg = 0;
imageYpos = yCenter - (dist_above_vert_center_deg * pixels_per_degree);
numImages = length(imageYpos);
imageXpos = [im1X im2X];

% Screen position of text
textAposDeg = 9;
textApos = yCenter + (textAposDeg * pixels_per_degree);
textLowPosDeg = 5;
textLowPos = yCenter + (textLowPosDeg * pixels_per_degree);

% Set the color
allColors = [0,0,0];

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Condition setup
numBlocks = 8;
numBlocksLessOne = numBlocks - 1;
conds = {'A1SH';'A1NH';'A2SH';'A2NH';'B1SH';'B1NH';'B2SH';'B2NH';...
         'A1SL';'A1NL';'A2SL';'A2NL';'B1SL';'B1NL';'B2SL';'B2NL'};
numConds = cat(1,conds,conds);
numConds = cellstr(numConds);
output.conditions = conds;
%A = Head A blocked
%B = Head B blocked
%1 = Dot appears in box 1
%2 = Dot appears in box 2
%S = Dot switches boxes
%N = Dot does not switch boxes
%H = Answering for higher/left head (A)
%L = Answering for lower/right head (B)

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 20;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;

% Box that dot appears in
box1 = CenterRectOnPointd(circleRect, squareXpos(1), squareYpos);
box2 = CenterRectOnPointd(circleRect, squareXpos(2), squareYpos);

% Key codes
escape = KbName('ESCAPE');
K_key  = KbName('k');
M_key  = KbName('m');
Y_key  = KbName('y');
N_key  = KbName('n');
Q_key  = KbName('q');
D_key  = KbName('d');
C_key  = KbName('c');
enter  = KbName('RETURN');

%k = Box 1
%m = Box 2

% Numbers
num1 = '1';
num2 = '2';

% Condition Images
blocked = [mainPath '\\images\\blocked.png'];
blockedCond = imread(blocked);
unblocked = [mainPath '\\images\\unblocked.png'];
unblockedCond = imread(unblocked);
blockedAns = [mainPath '\\images\\blockedAns.png'];
BACond = imread(blockedAns);
unblockedAns = [mainPath '\\images\\unblockedAns.png'];
nBACond = imread(unblockedAns);

% Make our rectangle coordinates
allRects = nan(4,2);
allIms = nan(4,2);
for i = 1:numSqaures
    allRects(:, i) = CenterRectOnPointd(baseRect, squareXpos(i), squareYpos);
    allIms(:, i) = CenterRectOnPointd(initRect, imageXpos(i), imageYpos);
end

% Make the image into a texture
nBCondTex  = Screen('MakeTexture', window, unblockedCond);
BCondTex   = Screen('MakeTexture', window, blockedCond);
nBACondTex = Screen('MakeTexture', window, nBACond);
BACondTex  = Screen('MakeTexture', window, BACond);

% Text
Screen('TextSize', window, 50);
Screen('TextFont', window, 'Times');
textA = 'Press either finger to continue.';
text16 = '\n\n You can begin the task when you are ready.';

HideCursor;
if handedness == 1
    RestrictKeysForKbCheck([escape enter K_key M_key]);
elseif handedness == 0
    RestrictKeysForKbCheck([escape enter D_key C_key]);
end
%% Instructions %%
if runIns == 1
    text1 = 'Thank you for participating in our study.';
    DrawFormattedText(window, text1, 'center', 'center', black);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text2 = 'We will now read through the instructions.';
    DrawFormattedText(window, text2, 'center', 'center', black);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text3 = 'As you go through the task, please keep your focus';
    text4 = '\n on the fixation cross in the center of the screen.';
    DrawFormattedText(window, [text3 text4], 'center', 'center', black);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text4b = 'Also, please try to respond as quickly as possible on each trial.';
    DrawFormattedText(window, text4b, 'center', 'center', black);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text5 = 'Two people will appear on screen.';
    DrawFormattedText(window, text5, 'center', textLowPos, black);
    Screen('DrawTextures', window, nBCondTex, [], allIms);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text6 = 'Next, a ball will appear in one of two boxes.';
    DrawFormattedText(window, text6, 'center', textLowPos, black);
    Screen('FrameRect', window, allColors, allRects, 5);
    Screen('DrawTextures', window, nBCondTex, [], allIms);
    DrawFormattedText(window, num1, num1X, numY, black);
    DrawFormattedText(window, num2, num2X, numY, black);
    Screen('FillOval', window, [1 0 0], box2);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text7 = 'After the ball is initially shown, one of the people on screen ';
    text8 = '\n will be blocked from seeing the boxes or the ball.';
    DrawFormattedText(window, [text7 text8], 'center', textLowPos, black);
    Screen('FrameRect', window, allColors, allRects, 5);
    Screen('DrawTextures', window, nBCondTex, [], allIms(:,2));
    Screen('DrawTextures', window, BCondTex, [], allIms(:,1));
    DrawFormattedText(window, num1, num1X, numY, black);
    DrawFormattedText(window, num2, num2X, numY, black);
    Screen('FillOval', window, [1 0 0], box2);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text9 = 'On some trials, after someone is blocked the ball will change boxes.';
    DrawFormattedText(window, text9, 'center', textLowPos, black);
    Screen('FrameRect', window, allColors, allRects, 5);
    Screen('DrawTextures', window, nBCondTex, [], allIms(:,2));
    Screen('DrawTextures', window, BCondTex, [], allIms(:,1));
    DrawFormattedText(window, num1, num1X, numY, black);
    DrawFormattedText(window, num2, num2X, numY, black);
    Screen('FillOval', window, [1 0 0], box2);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    DrawFormattedText(window, text9, 'center', textLowPos, black);
    Screen('FrameRect', window, allColors, allRects, 5);
    Screen('DrawTextures', window, nBCondTex, [], allIms(:,2));
    Screen('DrawTextures', window, BCondTex, [], allIms(:,1));
    DrawFormattedText(window, num1, num1X, numY, black);
    DrawFormattedText(window, num2, num2X, numY, black);
    Screen('FillOval', window, [1 0 0], box1);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text11 = 'Finally, a question mark (?) will appear inside of the head ';
    text11b = '\n of one of the people which looks like this.';
    DrawFormattedText(window, [text11 text11b], 'center', textLowPos, black);
    Screen('FrameRect', window, allColors, allRects, 5);
    Screen('DrawTextures', window, nBCondTex, [], allIms(:,2));
    Screen('DrawTextures', window, BACondTex, [], allIms(:,1));
    DrawFormattedText(window, num1, num1X, numY, black);
    DrawFormattedText(window, num2, num2X, numY, black);
    Screen('FillOval', window, [1 0 0], box1);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text12 = 'You must respond where the person with the question mark (?)';
    text12b = '\n will think the ball is located.';
    DrawFormattedText(window, [text12 text12b], 'center', textLowPos, black);
    Screen('FrameRect', window, allColors, allRects, 5);
    Screen('DrawTextures', window, nBCondTex, [], allIms(:,2));
    Screen('DrawTextures', window, BACondTex, [], allIms(:,1));
    DrawFormattedText(window, num1, num1X, numY, black);
    DrawFormattedText(window, num2, num2X, numY, black);
    Screen('FillOval', window, [1 0 0], box1);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    if handedness == 1
        text13 = 'Press your index finger if the person with the question';
    elseif handedness == 0
        text13 = 'Press your middle finger if the person with the question';
    end
    text13b = '\n mark will think the ball is in box 1.';
    DrawFormattedText(window, [text13 text13b], 'center', textLowPos, black);
    Screen('FrameRect', window, allColors, allRects, 5);
    Screen('DrawTextures', window, nBCondTex, [], allIms(:,2));
    Screen('DrawTextures', window, BACondTex, [], allIms(:,1));
    DrawFormattedText(window, num1, num1X, numY, black);
    DrawFormattedText(window, num2, num2X, numY, black);
    Screen('FillOval', window, [1 0 0], box1);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    if handedness == 1
        text14 = 'Press your middle finger if the person with the question';
    elseif handedness == 0
        text14 = 'Press your index finger if the person with the question';
    end
    text14a = '\n mark will think the ball is in box 2.';
    DrawFormattedText(window, [text14 text14a], 'center', textLowPos, black);
    Screen('FrameRect', window, allColors, allRects, 5);
    Screen('DrawTextures', window, nBCondTex, [], allIms(:,2));
    Screen('DrawTextures', window, BACondTex, [], allIms(:,1));
    DrawFormattedText(window, num1, num1X, numY, black);
    DrawFormattedText(window, num2, num2X, numY, black);
    Screen('FillOval', window, [1 0 0], box1);
    Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    text14b = 'Please remember to keep your focus on the fixation cross throughout the task,';
    text14c = '\n and to respond as quickly as you can.';
    DrawFormattedText(window, [text14b text14c], 'center', 'center', black);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if runPrac == 1
    %% Practice Runs %%
    textP = 'You can now begin the practice trials.';
    DrawFormattedText(window, textP, 'center', 'center', black);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
    practice_needed = 1;
    block = 1;
    BoxInitialVar = 0;
    BoxSwitchVar = 0;
    TopPersonVar = 0;
    BottomPersonVar = 0;
    TopPersonAnsVar = 0;
    BottomPersonAnsVar = 0;
    CorrectAnsVar = 0;
    while practice_needed == 1
        pracTempConds = randperm(numel(conds));
        pracConds = pracTempConds(1:8);
        pracRun = conds(pracConds);
        %%
        for trial = 1:numel(pracRun)
            thisTrialCond = strjoin(pracRun(trial));
            %% Setup %%
            [pTime0] = Screen('Flip', window);
            % Fixation cross only
            Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
            [pTime1] = Screen('Flip', window);
            % Wait for given amount of time
            WaitSecs(shortTime);
            % Draw the rect to the screen
            Screen('FrameRect', window, allColors, allRects, 5);
            % Draw the image to the screen
            Screen('DrawTextures', window, nBCondTex, [], allIms);
            % Draw numbers
            DrawFormattedText(window, num1, num1X, numY, black);
            DrawFormattedText(window, num2, num2X, numY, black);
            % Flip to the screen
            Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
            [pTime2] = Screen('Flip', window);
            % Wait for given amount of time
            WaitSecs(longTime);
            CueOnset = GetSecs;
            if strcmp(thisTrialCond,'A1SH')
                BoxInitialVar = box1;
                BoxSwitchVar = box2;
                TopPersonVar = BCondTex;
                BottomPersonVar = nBCondTex;
                TopPersonAnsVar = BACondTex;
                BottomPersonAnsVar = nBCondTex;
                CorrectAnsVar = 1;
            elseif strcmp(thisTrialCond,'A1NH')
                BoxInitialVar = box1;
                BoxSwitchVar = box1;
                TopPersonVar = BCondTex;
                BottomPersonVar = nBCondTex;
                TopPersonAnsVar = BACondTex;
                BottomPersonAnsVar = nBCondTex;
                CorrectAnsVar = 1;
            elseif strcmp(thisTrialCond,'A2SH')
                BoxInitialVar = box2;
                BoxSwitchVar = box1;
                TopPersonVar = BCondTex;
                BottomPersonVar = nBCondTex;
                TopPersonAnsVar = BACondTex;
                BottomPersonAnsVar = nBCondTex;
                CorrectAnsVar = 2;
            elseif strcmp(thisTrialCond,'A2NH')
                BoxInitialVar = box2;
                BoxSwitchVar = box2;
                TopPersonVar = BCondTex;
                BottomPersonVar = nBCondTex;
                TopPersonAnsVar = BACondTex;
                BottomPersonAnsVar = nBCondTex;
                CorrectAnsVar = 2;
            elseif strcmp(thisTrialCond,'B1SH')
                BoxInitialVar = box1;
                BoxSwitchVar = box2;
                TopPersonVar = nBCondTex;
                BottomPersonVar = BCondTex;
                TopPersonAnsVar = nBACondTex;
                BottomPersonAnsVar = BCondTex;
                CorrectAnsVar = 2;
            elseif strcmp(thisTrialCond,'B1NH')
                BoxInitialVar = box1;
                BoxSwitchVar = box1;
                TopPersonVar = nBCondTex;
                BottomPersonVar = BCondTex;
                TopPersonAnsVar = nBACondTex;
                BottomPersonAnsVar = BCondTex;
                CorrectAnsVar = 1;
            elseif strcmp(thisTrialCond,'B2SH')
                BoxInitialVar = box2;
                BoxSwitchVar = box1;
                TopPersonVar = nBCondTex;
                BottomPersonVar = BCondTex;
                TopPersonAnsVar = nBACondTex;
                BottomPersonAnsVar = BCondTex;
                CorrectAnsVar = 1;
            elseif strcmp(thisTrialCond,'B2NH')
                BoxInitialVar = box2;
                BoxSwitchVar = box2;
                TopPersonVar = nBCondTex;
                BottomPersonVar = BCondTex;
                TopPersonAnsVar = nBACondTex;
                BottomPersonAnsVar = BCondTex;
                CorrectAnsVar = 2;
            elseif strcmp(thisTrialCond,'A1SL')
                BoxInitialVar = box1;
                BoxSwitchVar = box2;
                TopPersonVar = BCondTex;
                BottomPersonVar = nBCondTex;
                TopPersonAnsVar = BCondTex;
                BottomPersonAnsVar = nBACondTex;
                CorrectAnsVar = 2;
            elseif strcmp(thisTrialCond,'A1NL')
                BoxInitialVar = box1;
                BoxSwitchVar = box1;
                TopPersonVar = BCondTex;
                BottomPersonVar = nBCondTex;
                TopPersonAnsVar = BCondTex;
                BottomPersonAnsVar = nBACondTex;
                CorrectAnsVar = 1;
            elseif strcmp(thisTrialCond,'A2SL')
                BoxInitialVar = box2;
                BoxSwitchVar = box1;
                TopPersonVar = BCondTex;
                BottomPersonVar = nBCondTex;
                TopPersonAnsVar = BCondTex;
                BottomPersonAnsVar = nBACondTex;
                CorrectAnsVar = 1;
            elseif strcmp(thisTrialCond,'A2NL')
                BoxInitialVar = box2;
                BoxSwitchVar = box2;
                TopPersonVar = BCondTex;
                BottomPersonVar = nBCondTex;
                TopPersonAnsVar = BCondTex;
                BottomPersonAnsVar = nBACondTex;
                CorrectAnsVar = 2;
            elseif strcmp(thisTrialCond,'B1SL')
                BoxInitialVar = box1;
                BoxSwitchVar = box2;
                TopPersonVar = nBCondTex;
                BottomPersonVar = BCondTex;
                TopPersonAnsVar = nBCondTex;
                BottomPersonAnsVar = BACondTex;
                CorrectAnsVar = 1;
            elseif strcmp(thisTrialCond,'B1NL')
                BoxInitialVar = box1;
                BoxSwitchVar = box1;
                TopPersonVar = nBCondTex;
                BottomPersonVar = BCondTex;
                TopPersonAnsVar = nBCondTex;
                BottomPersonAnsVar = BACondTex;
                CorrectAnsVar = 1;
            elseif strcmp(thisTrialCond,'B2SL')
                BoxInitialVar = box2;
                BoxSwitchVar = box1;
                TopPersonVar = nBCondTex;
                BottomPersonVar = BCondTex;
                TopPersonAnsVar = nBCondTex;
                BottomPersonAnsVar = BACondTex;
                CorrectAnsVar = 2;
            elseif strcmp(thisTrialCond,'B2NL')
                BoxInitialVar = box2;
                BoxSwitchVar = box2;
                TopPersonVar = nBCondTex;
                BottomPersonVar = BCondTex;
                TopPersonAnsVar = nBCondTex;
                BottomPersonAnsVar = BACondTex;
                CorrectAnsVar = 2;
            end
            data.conds{trial,block} = thisTrialCond;
            % Draw circle to box 1 or box 2 %
            % Draw the rect to the screen
            Screen('FrameRect', window, allColors, allRects, 5);
            % Draw the image to the screen
            Screen('DrawTextures', window, nBCondTex, [], allIms);
            % Draw numbers
            DrawFormattedText(window, num1, num1X, numY, black);
            DrawFormattedText(window, num2, num2X, numY, black);
            % Draw the circle to the screen
            Screen('FillOval', window, [1 0 0], BoxInitialVar);
            % Flip to the screen
            Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
            [pTime3] = Screen('Flip', window);
            % Wait for given amount of time
            WaitSecs(longTime);
            % Person A or B blocked %
            % Draw the rect to the screen
            Screen('FrameRect', window, allColors, allRects, 5);
            % Draw the image to the screen
            Screen('DrawTextures', window, TopPersonVar, [], allIms(:,1));
            Screen('DrawTextures', window, BottomPersonVar, [], allIms(:,2));
            % Draw numbers
            DrawFormattedText(window, num1, num1X, numY, black);
            DrawFormattedText(window, num2, num2X, numY, black);
            % Draw the circle to the screen
            Screen('FillOval', window, [1 0 0], BoxInitialVar);
            % Flip to the screen
            Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
            [pTime4] = Screen('Flip', window);
            % Wait for given amount of time
            WaitSecs(longTime);
            % Switch or no switch %
            % Draw the rect to the screen
            Screen('FrameRect', window, allColors, allRects, 5);
            % Draw the image to the screen
            Screen('DrawTextures', window, TopPersonVar, [], allIms(:,1));
            Screen('DrawTextures', window, BottomPersonVar, [], allIms(:,2));
            % Draw numbers
            DrawFormattedText(window, num1, num1X, numY, black);
            DrawFormattedText(window, num2, num2X, numY, black);
            % Draw the circle to the screen
            Screen('FillOval', window, [1 0 0], BoxSwitchVar);
            % Flip to the screen
            Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
            [pTime5] = Screen('Flip', window);
            % Wait for given amount of time
            WaitSecs(shortTime);
            % Answer for person A or B %
            % Draw the rect to the screen
            Screen('FrameRect', window, allColors, allRects, 5);
            % Draw the image to the screen
            Screen('DrawTextures', window, TopPersonAnsVar, [], allIms(:,1));
            Screen('DrawTextures', window, BottomPersonAnsVar, [], allIms(:,2));
            % Draw numbers
            DrawFormattedText(window, num1, num1X, numY, black);
            DrawFormattedText(window, num2, num2X, numY, black);
            % Draw the circle to the screen
            Screen('FillOval', window, [1 0 0], BoxSwitchVar);
            % Flip to the screen
            Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
            [pTime6] = Screen('Flip', window);
            targetOnset = GetSecs;
            correct_response = CorrectAnsVar;
            data.corrResp{trial,block} = correct_response;
            data.cueStart{trial,block} = targetOnset;
            subject_response = 0;
            waiting = 1;
            while waiting
                [KeyPress, keyTime, keyCode] = KbCheck;
                if KeyPress
                    if keyCode(K_key) || keyCode(D_key)
                        subject_response = 1;
                        reaction_time = keyTime;
                    elseif keyCode(M_key) || keyCode(C_key)
                        subject_response = 2;
                        reaction_time = keyTime;
                    elseif keyCode(escape)
                        ShowCursor;
                        Screen('CloseAll')
                        keyboard
                        continue;
                    end
                    data.subjResp{trial,block} = subject_response;
                    data.rt{trial,block} = reaction_time;
                end
                if GetSecs - targetOnset >= responseTime
                    dispTime = GetSecs;
                    waiting = 0;
                    if subject_response == 0
                        data.subjResp{trial,block} = NaN;
                        data.rt{trial,block} = NaN;
                        textTS = 'TOO SLOW!';
                        DrawFormattedText(window, textTS, 'center', 'center', black);
                        Screen('Flip', window);
                        WaitSecs(longTime);
                    end
                end
            end
            [pTime7] = Screen('Flip', window);
            if subject_response > 0
                WaitSecs(1);
            else
                WaitSecs(0.5);
            end
            [pTime8] = GetSecs;

            data.pTimes{trial,1}  = pTime0;
            data.pTimes{trial,2}  = pTime1;
            data.pTimes{trial,3}  = pTime2;
            data.pTimes{trial,4}  = pTime3;
            data.pTimes{trial,5}  = pTime4;
            data.pTimes{trial,6}  = pTime5;
            data.pTimes{trial,7}  = pTime6;
            data.pTimes{trial,8}  = pTime7;
            data.pTimes{trial,9}  = pTime8;
            data.pTimes{trial,10} = pTime8-pTime0;
        end
        RestrictKeysForKbCheck([escape Y_key N_key]);
        Screen('Flip', window);
        textQ1 = 'Do you need more practice?';
        DrawFormattedText(window, textQ1, 'center', 'center', black);
        Screen('Flip', window);
        KbWait;
        [KeyPress, ~, keyCode] = KbCheck;
        if KeyPress
            if keyCode(Y_key)
                practice_needed = 1;
            elseif keyCode(N_key)
                practice_needed = 0;
            elseif keyCode(escape)
                ShowCursor;
                Screen('CloseAll')
                keyboard
                continue;
            end
        end
    end
    if handedness == 1
        RestrictKeysForKbCheck([escape K_key M_key]);
    elseif handedness == 0
        RestrictKeysForKbCheck([escape D_key C_key]);
    end
    Screen('Flip', window);
    text15 = 'You have completed the practice trials.';
    DrawFormattedText(window, [text15 text16], 'center', 'center', black);
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
end
textB = 'You can now begin the main experiment.';
DrawFormattedText(window, textB, 'center', 'center', black);
DrawFormattedText(window, textA, 'center', textApos, black);
Screen('Flip', window);
KbStrokeWait;
text17 = (['You are starting run 1 of ' num2str(numBlocks)]);
text18 = '\n\n Please remember to respond as quickly as you can.';
DrawFormattedText(window, [text17 text18 text16], 'center', 'center', black);
DrawFormattedText(window, textA, 'center', textApos, black);
Screen('Flip', window);
KbStrokeWait;
[KeyPress, ~, keyCode] = KbCheck;
if KeyPress
    if keyCode(escape)
        ShowCursor;
        Screen('CloseAll')
    end
end
%% Experimental Loop %%
for block = 1:numBlocks
    if handedness == 1
        RestrictKeysForKbCheck([escape K_key M_key]);
    elseif handedness == 0
        RestrictKeysForKbCheck([escape D_key C_key]);
    end
    tempConds = randperm(numel(numConds));
    run = numConds(tempConds);
    numTrials = numel(run);
    RUN_START_TIME = GetSecs;
    for trial = 1:numTrials
        thisTrialCond = strjoin(run(trial));
        %% Setup %%
        % Flip to the screen
        [eTime0] = Screen('Flip', window);
        % Fixation cross only
        Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
        [eTime1] = Screen('Flip', window);
        % Wait for given amount of time
        WaitSecs(shortTime);
        % Draw the rect to the screen
        Screen('FrameRect', window, allColors, allRects, 5);
        % Draw the image to the screen
        Screen('DrawTextures', window, nBCondTex, [], allIms);
        % Draw numbers
        DrawFormattedText(window, num1, num1X, numY, black);
        DrawFormattedText(window, num2, num2X, numY, black);
        % Flip to the screen
        Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
        [eTime2] = Screen('Flip', window);
        % Wait for given amount of time
        WaitSecs(longTime);
        CueOnset = GetSecs;
        if strcmp(thisTrialCond,'A1SH')
            BoxInitialVar = box1;
            BoxSwitchVar = box2;
            TopPersonVar = BCondTex;
            BottomPersonVar = nBCondTex;
            TopPersonAnsVar = BACondTex;
            BottomPersonAnsVar = nBCondTex;
            CorrectAnsVar = 1;
        elseif strcmp(thisTrialCond,'A1NH')
            BoxInitialVar = box1;
            BoxSwitchVar = box1;
            TopPersonVar = BCondTex;
            BottomPersonVar = nBCondTex;
            TopPersonAnsVar = BACondTex;
            BottomPersonAnsVar = nBCondTex;
            CorrectAnsVar = 1;
        elseif strcmp(thisTrialCond,'A2SH')
            BoxInitialVar = box2;
            BoxSwitchVar = box1;
            TopPersonVar = BCondTex;
            BottomPersonVar = nBCondTex;
            TopPersonAnsVar = BACondTex;
            BottomPersonAnsVar = nBCondTex;
            CorrectAnsVar = 2;
        elseif strcmp(thisTrialCond,'A2NH')
            BoxInitialVar = box2;
            BoxSwitchVar = box2;
            TopPersonVar = BCondTex;
            BottomPersonVar = nBCondTex;
            TopPersonAnsVar = BACondTex;
            BottomPersonAnsVar = nBCondTex;
            CorrectAnsVar = 2;
        elseif strcmp(thisTrialCond,'B1SH')
            BoxInitialVar = box1;
            BoxSwitchVar = box2;
            TopPersonVar = nBCondTex;
            BottomPersonVar = BCondTex;
            TopPersonAnsVar = nBACondTex;
            BottomPersonAnsVar = BCondTex;
            CorrectAnsVar = 2;
        elseif strcmp(thisTrialCond,'B1NH')
            BoxInitialVar = box1;
            BoxSwitchVar = box1;
            TopPersonVar = nBCondTex;
            BottomPersonVar = BCondTex;
            TopPersonAnsVar = nBACondTex;
            BottomPersonAnsVar = BCondTex;
            CorrectAnsVar = 1;
        elseif strcmp(thisTrialCond,'B2SH')
            BoxInitialVar = box2;
            BoxSwitchVar = box1;
            TopPersonVar = nBCondTex;
            BottomPersonVar = BCondTex;
            TopPersonAnsVar = nBACondTex;
            BottomPersonAnsVar = BCondTex;
            CorrectAnsVar = 1;
        elseif strcmp(thisTrialCond,'B2NH')
            BoxInitialVar = box2;
            BoxSwitchVar = box2;
            TopPersonVar = nBCondTex;
            BottomPersonVar = BCondTex;
            TopPersonAnsVar = nBACondTex;
            BottomPersonAnsVar = BCondTex;
            CorrectAnsVar = 2;
        elseif strcmp(thisTrialCond,'A1SL')
            BoxInitialVar = box1;
            BoxSwitchVar = box2;
            TopPersonVar = BCondTex;
            BottomPersonVar = nBCondTex;
            TopPersonAnsVar = BCondTex;
            BottomPersonAnsVar = nBACondTex;
            CorrectAnsVar = 2;
        elseif strcmp(thisTrialCond,'A1NL')
            BoxInitialVar = box1;
            BoxSwitchVar = box1;
            TopPersonVar = BCondTex;
            BottomPersonVar = nBCondTex;
            TopPersonAnsVar = BCondTex;
            BottomPersonAnsVar = nBACondTex;
            CorrectAnsVar = 1;
        elseif strcmp(thisTrialCond,'A2SL')
            BoxInitialVar = box2;
            BoxSwitchVar = box1;
            TopPersonVar = BCondTex;
            BottomPersonVar = nBCondTex;
            TopPersonAnsVar = BCondTex;
            BottomPersonAnsVar = nBACondTex;
            CorrectAnsVar = 1;
        elseif strcmp(thisTrialCond,'A2NL')
            BoxInitialVar = box2;
            BoxSwitchVar = box2;
            TopPersonVar = BCondTex;
            BottomPersonVar = nBCondTex;
            TopPersonAnsVar = BCondTex;
            BottomPersonAnsVar = nBACondTex;
            CorrectAnsVar = 2;
        elseif strcmp(thisTrialCond,'B1SL')
            BoxInitialVar = box1;
            BoxSwitchVar = box2;
            TopPersonVar = nBCondTex;
            BottomPersonVar = BCondTex;
            TopPersonAnsVar = nBCondTex;
            BottomPersonAnsVar = BACondTex;
            CorrectAnsVar = 1;
        elseif strcmp(thisTrialCond,'B1NL')
            BoxInitialVar = box1;
            BoxSwitchVar = box1;
            TopPersonVar = nBCondTex;
            BottomPersonVar = BCondTex;
            TopPersonAnsVar = nBCondTex;
            BottomPersonAnsVar = BACondTex;
            CorrectAnsVar = 1;
        elseif strcmp(thisTrialCond,'B2SL')
            BoxInitialVar = box2;
            BoxSwitchVar = box1;
            TopPersonVar = nBCondTex;
            BottomPersonVar = BCondTex;
            TopPersonAnsVar = nBCondTex;
            BottomPersonAnsVar = BACondTex;
            CorrectAnsVar = 2;
        elseif strcmp(thisTrialCond,'B2NL')
            BoxInitialVar = box2;
            BoxSwitchVar = box2;
            TopPersonVar = nBCondTex;
            BottomPersonVar = BCondTex;
            TopPersonAnsVar = nBCondTex;
            BottomPersonAnsVar = BACondTex;
            CorrectAnsVar = 2;
        end
        data.conds{trial,block} = thisTrialCond;
        % Draw circle to box 1 or box 2 %
        % Draw the rect to the screen
        Screen('FrameRect', window, allColors, allRects, 5);
        % Draw the image to the screen
        Screen('DrawTextures', window, nBCondTex, [], allIms);
        % Draw numbers
        DrawFormattedText(window, num1, num1X, numY, black);
        DrawFormattedText(window, num2, num2X, numY, black);
        % Draw the circle to the screen
        Screen('FillOval', window, [1 0 0], BoxInitialVar);
        % Flip to the screen
        Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
        [eTime3] = Screen('Flip', window);
        % Wait for given amount of time
        WaitSecs(longTime);
        % Person A or B blocked %
        % Draw the rect to the screen
        Screen('FrameRect', window, allColors, allRects, 5);
        % Draw the image to the screen
        Screen('DrawTextures', window, TopPersonVar, [], allIms(:,1));
        Screen('DrawTextures', window, BottomPersonVar, [], allIms(:,2));
        % Draw numbers
        DrawFormattedText(window, num1, num1X, numY, black);
        DrawFormattedText(window, num2, num2X, numY, black);
        % Draw the circle to the screen
        Screen('FillOval', window, [1 0 0], BoxInitialVar);
        % Flip to the screen
        Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
        [eTime4] = Screen('Flip', window);
        % Wait for given amount of time
        WaitSecs(longTime);
        % Switch or no switch %
        % Draw the rect to the screen
        Screen('FrameRect', window, allColors, allRects, 5);
        % Draw the image to the screen
        Screen('DrawTextures', window, TopPersonVar, [], allIms(:,1));
        Screen('DrawTextures', window, BottomPersonVar, [], allIms(:,2));
        % Draw numbers
        DrawFormattedText(window, num1, num1X, numY, black);
        DrawFormattedText(window, num2, num2X, numY, black);
        % Draw the circle to the screen
        Screen('FillOval', window, [1 0 0], BoxSwitchVar);
        % Flip to the screen
        Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
        [eTime5] = Screen('Flip', window);
        % Wait for given amount of time
        WaitSecs(shortTime);
        % Answer for person A or B %
        % Draw the rect to the screen
        Screen('FrameRect', window, allColors, allRects, 5);
        % Draw the image to the screen
        Screen('DrawTextures', window, TopPersonAnsVar, [], allIms(:,1));
        Screen('DrawTextures', window, BottomPersonAnsVar, [], allIms(:,2));
        % Draw numbers
        DrawFormattedText(window, num1, num1X, numY, black);
        DrawFormattedText(window, num2, num2X, numY, black);
        % Draw the circle to the screen
        Screen('FillOval', window, [1 0 0], BoxSwitchVar);
        % Flip to the screen
        Screen('DrawLines', window, allCoords,lineWidthPix, black, [xCenter yCenter], 2);
        [eTime6] = Screen('Flip', window);
        targetOnset = GetSecs;
        correct_response = CorrectAnsVar;
        data.corrResp{trial,block} = correct_response;
        data.cueStart{trial,block} = targetOnset;
        subject_response = 0;
        waiting = 1;
        while waiting
            [KeyPress, keyTime, keyCode] = KbCheck;
            if KeyPress
                if keyCode(K_key) || keyCode(D_key)
                    subject_response = 1;
                    reaction_time = keyTime;
                elseif keyCode(M_key) || keyCode(C_key)
                    subject_response = 2;
                    reaction_time = keyTime;
                elseif keyCode(escape)
                    ShowCursor;
                    Screen('CloseAll')
                    continue;
                end
                data.subjResp{trial,block} = subject_response;
                data.rt{trial,block} = reaction_time;
            end
            if GetSecs - targetOnset >= responseTime
                dispTime = GetSecs;
                waiting = 0;
                if subject_response == 0
                    data.subjResp{trial,block} = NaN;
                    data.rt{trial,block} = NaN;
                    textTS = 'TOO SLOW!';
                    DrawFormattedText(window, textTS, 'center', 'center', black);
                    Screen('Flip', window);
                    WaitSecs(longTime);
                end
            end
        end
        [eTime7] = Screen('Flip', window);
        if subject_response > 0
            WaitSecs(1);
        else
            WaitSecs(0.5);
        end
        [eTime8] = GetSecs;

        data.runStart{block,1}      = RUN_START_TIME;
        data.eTimes{trial,1,block}  = eTime0;
        data.eTimes{trial,2,block}  = eTime1;
        data.eTimes{trial,3,block}  = eTime2;
        data.eTimes{trial,4,block}  = eTime3;
        data.eTimes{trial,5,block}  = eTime4;
        data.eTimes{trial,6,block}  = eTime5;
        data.eTimes{trial,7,block}  = eTime6;
        data.eTimes{trial,8,block}  = eTime7;
        data.eTimes{trial,9,block}  = eTime8;
        data.eTimes{trial,10,block} = eTime8-eTime0;
    end
    % Save data
    output.data = data;
    save(char(server_filename), 'data');
    save(char(server_filenameV));
    Screen('Flip', window);
    
    text19 = (['You have completed run ' num2str(block) ' of ' num2str(numBlocks)]);
    text20 = '\n\n You can take a moment to rest. Begin the next block when you are ready.';
    if block <= numBlocksLessOne
        DrawFormattedText(window, [text19 text20], 'center', 'center', black);
    elseif block > numBlocksLessOne
        DrawFormattedText(window, text19, 'center', 'center', black);
    end
    DrawFormattedText(window, textA, 'center', textApos, black);
    Screen('Flip', window);
    KbStrokeWait;
end
%% Concluding text %%
RestrictKeysForKbCheck(Q_key);
textEnd = 'Thank you! Please wait for the experimenter.';
DrawFormattedText(window, textEnd, 'center', 'center', black);
% Flip to the screen
Screen('Flip', window);
% Wait for a key press
KbStrokeWait;
% Clear the screen
Priority(0);
ShowCursor;
RestrictKeysForKbCheck([]);
sca;
catch error
    save(char(server_filename), 'data');
    save(char(server_filenameV));
    ShowCursor;
    Screen('CloseAll')
    disp(error)
    keyboard
end
