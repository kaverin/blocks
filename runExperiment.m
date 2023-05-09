function runExperiment
%--------------------------------------------------------------------------
%% Language Demonstratives
% Kristiina Averin, December 2015
%--------------------------------------------------------------------------
%% description of the code
% Colour-picking with PsychToolbox OpenGL.
% Presents a set of construction blocks on a table with an opporturnity to add auditory instruction/stimulus.
% Allows to identify offscreen colour of the item that has been klicked on and 
% thus bypass the need to convert 3D OpenGL coordinates to 2D screen
% coordinates. However comes at the cost of time. 
% Uses pseudorandom order for presenting the stimuli.  

%% to exit the experiment-  ESC - possible while the response is waited and not during the time audio is played

%% colour codes 
%      0 0 1 (blue)    -        first block
%      1 0 0 (red)     -        second block
%      1 1 0 (yellow)  -        third block
%      1 1 1 (white)   -        do not know (button at the top-right corner of the screen)
%      9 9 9           -        no answer given

%% variables that will be saved in the output file
% ParticipantID        -        Participant ID entered at the beginning of the experiment
% TrialNr              -        number of trial
% visual_stimulus      -        name of visual stimulus presented. In the first row of the settings file.  
% instruction          -        instruction/auditory stimulus  
% blockPicked
% nrOfBlocks           -        nr of pieces (set to 3). For additional pieces, the settings file needs to be updated.
% B1xTableCoord        -        Table coordinate x of the 1. block. Table coordinates differ from the screen coordinates 
% B1yTableCoord        -        Table coordinate y of the 1. block.
% B1rotation           -        Is the 1. block rotated 90 degrees. V if vertical, H if horisontal.
% B2xTableCoord        -        Table coordinate x of the 2. block.
% B2yTableCoord        -        Table coordinate y of the 2. block.
% B2rotation           -        Is the 2. block rotated 90 degrees. V if vertical, H if horisontal.
% B3xTableCoord        -        Table coordinate x of the 3. block.
% B3yTableCoord        -        Table coordinate y of the 3. block.
% B3rotation           -        Is the 3. block rotated 90 degrees. V if vertical, H if horisontal.
% B4xTableCoord        -        Table coordinate x of the 4. block.
% B4yTableCoord        -        Table coordinate y of the 4. block.
% B4rotation           -        Is the 4. block rotated 90 degrees. V if vertical, H if horisontal.
% B5xTableCoord        -        Table coordinate x of the 5. block.
% B5yTableCoord        -        Table coordinate y of the 5. block.
% B5rotation           -        Is the 5. block rotated 90 degrees. V if vertical, H if horisontal.
% B6xTableCoord        -        Table coordinate x of the 6. block.
% B6yTableCoord        -        Table coordinate y of the 6. block.
% B6rotation           -        Is the 6. block rotated 90 degrees. V if vertical, H if horisontal.
% x_mouse              -        screen coordinate x of the mouse click.
%                               differs from the coordinates of the table.                               
% y_mouse              -        screen coordinate x of the mouse click.
% R                    -        red colour in the pixel clicked (1/0)
% G                    -        green colour in the pixel clicked (1/0)
% B                    -        blue colour in the pixel clicked (1/0)
% rTime                -        response time
%--------------------------------------------------------------------------
%% allows to add a dialog box
%x = inputdlg({'Participant ID', 'Version' },...
%              ' ', [1 50; 1 12]); 
%disp(x);
%ParticipantID=x{1};
%versioon=str2double(x{3});

ParticipantID='kristiina';
%-------------------------------------------------------------------------
%% audio setup
%if testing with audio, the names of the files should be specified here.
%expects to have file names for the autitory (.wav) stimuli without file extensions 
instructions={'sealt-see-klots', 'sealt-too-klots', 'see-klots', 'see-klots-sealt', 'see-klots-siit', 'siit-see-klots', 'siit-too-klots', 'too-klots', 'too-klots-sealt', 'too-klots-siit'};
%instructions={};

%% settings for visual stimuli
%reads in the the locations for the visual stimuli (blocks).
%First number x-axis of the table, second number, y-axis of the table. H -horisontal block, V - vertical block. 
%reads in the text file with predetermined locations and rotations for the blocks and creates a  
%C = readcell('BlockSettingsV1.txt');
%aStructure =cell2struct(C(:,2:end), C(1:14), 1);
%conditionSettings = struct();
%for i=1:length(aStructure)
%    field=C{1:i};
%    conditionSettings.(field)=deal(C(i,2:end));
%end

%produces preset number of blocks. 
nrOfBlocks=3; %Number of blocks on the table (1-6).
nrOfConditions=4;%
conditionSettings =createRandomCoordinates(nrOfBlocks, nrOfConditions);

%% results file
%sets the results folder
resultsFolder = 'Results';

%name of the results file, that contains Participant ID, date and time
outputfile = fopen([resultsFolder '/LanguageDemonstratives_' num2str(ParticipantID), '_', strrep(strrep(datestr(now), ' ', '_'), ':', '-') '.txt'],'w');
fprintf(outputfile, 'ParticipantID\t TrialNr\t visual_stimulus\t instruction\t blockPicked,\t nrOfBlocks\t B1xTableCoord\t B1yTableCoord\t B1rotation\t B2xTableCoord\t B2yTableCoord\t B2rotation\t B3xTableCoord\t B3yTableCoord\t B3rotation\t x_mouse\t y_mouse\t R\t G\t B\t rTime\t\r\n');
%--------------------------------------------------------------------------
%% general setup
PsychDefaultSetup(2);
InitializeMatlabOpenGL(1);
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 3);
%--------------------------------------------------------------------------
%% creating the window
screenid=max(Screen('Screens'));

%creates a window for the stimuli
[win , winRect] = Screen('OpenWindow', screenid);
ar=winRect(4)/winRect(3);

%creates a window not shown on the screen that contains a copy of the blocks
%in different colours which eventually help to identify the block picked. 
[winOffSc, rectOffSc]=Screen('OpenOffscreenWindow',screenid);

%opens the visible window
Screen('BeginOpenGL', win);

%--------------------------------------------------------------------------
%% lightning and viewing position
glLightModelfv(GL_LIGHT_MODEL_TWO_SIDE,GL_TRUE);
glEnable(GL_DEPTH_TEST);
glMaterialfv(GL_FRONT_AND_BACK,GL_SHININESS,27.8);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;

gluPerspective(25,1/ar,0.1,100);

glMatrixMode(GL_MODELVIEW);

%to window coordinates 
glViewport(0, 0, winRect(RectRight),winRect(RectBottom));

glLoadIdentity;
%sets the viewing transformation 
gluLookAt(0,5,30,0,2,0,0,1,0);

%colour of the background
glClearColor(0.5,0.5,0.5,0);

%location of the light source
glLightfv(GL_LIGHT0,GL_POSITION,[ 1 2 3 0 ]);

%hue of the light source
glLightfv(GL_LIGHT0,GL_DIFFUSE, [ 1 1 1 1 ]);
glLightfv(GL_LIGHT0,GL_AMBIENT, [ .1 .1 .1 1 ]);

glEnable(GL_LIGHTING);
glEnable(GL_LIGHT0);

%closes the 3D window
Screen('EndOpenGL', win);
%--------------------------------------------------------------------------
%% presents the stimuli
try
    presentStimuli(ParticipantID, nrOfBlocks, conditionSettings, instructions, win , winRect, winOffSc, outputfile);

catch
    disp('Ohh, well then!');
end
%--------------------------------------------------------------------------
%% closes the experiment
%ending text
Screen('DrawText',win,'End of the experiment.', winRect(RectRight)/3, winRect(RectBottom)/2, [0 0 0]);
Screen('Flip',win);

%waits for two seconds
WaitSecs(2);

%closes the experiment
Screen('CloseAll');

return
