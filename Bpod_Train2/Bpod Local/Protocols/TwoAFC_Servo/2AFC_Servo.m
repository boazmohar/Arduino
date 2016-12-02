%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA
    
----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
function 2AFC_Servo()
% This protocol is a starting point for a tactile 2AFC task.
% Written by Nuo Li, 7/2016.
% Cahnge to Servo control and milk delivery by Boaz Mohar 11/2016
% SETUP
% You will need:
% - A Bpod MouseBox (or equivalent) configured with: 
% > Port#1: Left lickport (detection only)
% > Port#2: Right lickport (detection only)
% > Port#3: BNC1 - Stimulus duration to arduino controling servo
% > Port#4: BNC2 - Go Cue sound

global BpodSystem S;


%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    
    S.GUI.WaterValveTime = 0.05;        % in sec
    S.GUI.PreSamplePeriod = 0.5;        % in sec
    S.GUI.SamplePeriod = 0.7;           % in sec
    S.GUI.DelayPeriod = 0.1;            % in sec
    S.GUI.AnswerPeriod = 1.5;           % in sec
    S.GUI.ConsumptionPeriod = 1.5;      % in sec
    S.GUI.StopLickingPeriod = 1;        % in sec
    S.GUI.ITI = 2;                      % in sec
    S.GUI.ExtraITI = 0.01;              % in sec
    S.GUIPanels.TrialStructure= {'PreSamplePeriod', 'SamplePeriod','DelayPeriod','AnswerPeriod','ConsumptionPeriod','StopLickingPeriod','ITI', 'ExtraITI'};
    
    S.GUI.ValveTimeRight = 0.2;         % in sec
    S.GUI.ValveTimeLeft = 0.2;          % in sec
    
    S.GUIPanels.ValveTimes = {'ValveTimeRight', 'ValveTimeLeft'};
    
    S.GUIMeta.TrialType.Style = 'popupmenu';     % protocol type selection
    S.GUIMeta.TrialType.String = {'Licking', 'yes_no_servo_delay'};
    S.GUI.TrialType = 'yes_no_servo_delay';            

    S.GUIMeta.Autolearn.Style = 'popupmenu';     % trial type selection
    S.GUIMeta.Autolearn.String = {'autolearn' 'antiBias', 'off'};
    S.GUI.Autolearn = 'autolearn';             
    S.GUI.MaxSame = 3;
    S.GUI.RightTrialProb = 0.5;
    S.GUI.Min_correct_Right = 1;
    S.GUI.Max_incorrect_Right = 3;
    S.GUI.Min_correct_Left = 1;
    S.GUI.Max_incorrect_Left = 3;
    
    S.GUIPanels.TrialSelection= {'TrialType', 'Autolearn','MaxSame','RightTrialProb','Min_correct_Right','Max_incorrect_Right','Min_correct_Left','Max_incorrect_Left'};

end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);

% sync the protocol selections
p = cellfun(@(x) strcmp(x,'Lick_Max_YesNo_Del'),BpodSystem.GUIHandles.ParameterGUI.ParamNames);
set(BpodSystem.GUIHandles.ParameterGUI.ParamValues(p),'callback',{@manualChangeProtocol, S})

p = cellfun(@(x) strcmp(x,'Autolearn_Antibias'),BpodSystem.GUIHandles.ParameterGUI.ParamNames);
set(BpodSystem.GUIHandles.ParameterGUI.ParamValues(p),'callback',{@manualChangeAutolearn, S})

p = cellfun(@(x) strcmp(x,'MaxPower'),BpodSystem.GUIHandles.ParameterGUI.ParamNames);
set(BpodSystem.GUIHandles.ParameterGUI.ParamValues(p),'callback',{@programPulsePalSineWave, 1, 'MaxPower'})

p = cellfun(@(x) strcmp(x,'StimPower'),BpodSystem.GUIHandles.ParameterGUI.ParamNames);
set(BpodSystem.GUIHandles.ParameterGUI.ParamValues(p),'callback',{@programPulsePalSineWave, 1, 'StimPower'})

p = cellfun(@(x) strcmp(x,'StimLength'),BpodSystem.GUIHandles.ParameterGUI.ParamNames);
set(BpodSystem.GUIHandles.ParameterGUI.ParamValues(p),'callback',{@programPulsePalSineWave, 1, 'StimLength'})


%% Define trials
MaxTrials = 9999;
% TrialTypes = ceil(rand(1,1000)*2);
TrialTypes = [];
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.

%% Initialize plots
BpodSystem.ProtocolFigures.YesNoPerfOutcomePlotFig = figure('Position', [200 100 1400 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off', 'Color', [1 1 1]);
BpodSystem.GUIHandles.YesNoPerfOutcomePlot = axes('Position', [.2 .2 .75 .7]);

uicontrol('Style', 'text', 'String', 'nDisplay: ','Position',[10 170 45 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);
BpodSystem.GUIHandles.DisplayNTrials = uicontrol('Style','edit','string','100','Position',[55 170 40 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);

uicontrol('Style', 'text', 'String', 'hit % (all): ','Position',[10 140 60 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);
BpodSystem.GUIHandles.hitpct = uicontrol('Style','text','string','0','Position',[75 140 40 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);

uicontrol('Style', 'text', 'String', 'hit % (40): ','Position',[10 120 60 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);
BpodSystem.GUIHandles.hitpctrecent = uicontrol('Style','text','string','0','Position',[75 120 40 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);

uicontrol('Style', 'text', 'String', 'hit % (right): ','Position',[10 90 60 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);
BpodSystem.GUIHandles.hitpctright = uicontrol('Style','text','string','0','Position',[75 90 40 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);

uicontrol('Style', 'text', 'String', 'hit % (left): ','Position',[10 70 60 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);
BpodSystem.GUIHandles.hitpctleft = uicontrol('Style','text','string','0','Position',[75 70 40 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);

uicontrol('Style', 'text', 'String', 'Trials: ','Position',[10 40 60 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);
BpodSystem.GUIHandles.numtrials = uicontrol('Style','text','string','0','Position',[75 40 40 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);

uicontrol('Style', 'text', 'String', 'Rewards: ','Position',[10 20 60 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);
BpodSystem.GUIHandles.numrewards = uicontrol('Style','text','string','0','Position',[75 20 40 15], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]);


YesNoPerfOutcomePlot(BpodSystem.GUIHandles.YesNoPerfOutcomePlot,1,'init',0);
% BpodNotebook('init');

programPulsePalSineWave([], [], 1, 'Init');

% Pause the protocol before starting
BpodSystem.Pause = 1;
HandlePauseCondition;


% define outputs
io.LeftWater  = {'ValveState',2^0};
io.RightWater = {'ValveState',2^1};
io.Pole = {'PWM3',255};
io.Cue = {'ValveState',2^3};
io.Alarm = {'ValveState',2^4};
io.WSTrig = {'PWM6',255};
io.Bitcode = {'PWM7',255};
io.SampleStimOn = {'BNCState', 3};
io.SampleStimOff = {'BNCState', 2};
io.WaterOff = {'ValveState',0};




%% Main trial loop
for currentTrial = 1:MaxTrials
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    
    % select trials here
    disp(['Starting trial ',num2str(currentTrial)])
    TrialTypes(currentTrial) = trialSelection;        %0's (right) or 1's (left) 
%     YesNoPerfOutcomePlot(BpodSystem.GUIHandles.YesNoPerfOutcomePlot,BpodSystem.GUIHandles.DisplayNTrials,'next_trial',TrialTypes(currentTrial));
    YesNoPerfOutcomePlot(BpodSystem.GUIHandles.YesNoPerfOutcomePlot,currentTrial,'next_trial',TrialTypes(currentTrial), BpodSystem.GUIHandles.DisplayNTrials);
    %disp(['Starting trial ',num2str(currentTrial),' TrialType: ' num2str(TrialTypes(currentTrial))])
    
    
    % perhaps start sma and add bitcode at the top
    
    % build state matrix depending on the protocol type
    switch S.GUI.Lick_Max_YesNo_Del
        
                  
        case 1          % Licking
            
            sma = NewStateMatrix(); % Assemble state matrix
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer', 30,...
                'StateChangeConditions', {'Port1In', 'OpenvalveL', 'Port2In', 'OpenvalveR','Tup', 'TrialEnd'},...
                'OutputActions', [io.SampleStimOn]);
            sma = AddState(sma, 'Name', 'OpenvalveL', ...
                'Timer', S.GUI.WaterValveTime,...
                'StateChangeConditions', {'Tup', 'TrialEnd'},...
                'OutputActions',  {'ValveState',2^0 + 2^3});
            sma = AddState(sma, 'Name', 'OpenvalveR', ...
                'Timer', S.GUI.WaterValveTime,...
                'StateChangeConditions', {'Tup', 'TrialEnd'},...
                'OutputActions', {'ValveState',2^1 + 2^3});
            sma = AddState(sma, 'Name', 'TrialEnd', ...
                'Timer', 0.05,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', [io.WaterOff]);
            
        case 2  %Stim on max
            addpath(genpath('C:\PulsePal\MATLAB'));
            pp.wave = 5*ones(1, 1000);
            chan = 1;
            
            PulsePal;
            ProgramPulsePalParam(chan, 14 , chan); % Sets output channel 1 to use custom train 1
            ProgramPulsePalParam(chan, 12 , chan); % Sets output channel 1 to respond to triggers on trigger channel 1
            ProgramPulsePalParam(chan, 128 , 2);  %Sets output channel 1 to gating mode
            SendCustomWaveform(chan, 0.1, pp.wave); % Uploads constant waveform
            
            EndPulsePal();
            
            sma = NewStateMatrix();
            sma = AddState(sma, 'Name', 'MaxOutput', ...
                'Timer', 5,...
                'StateChangeConditions', {'Port1In', 'TrialEnd', 'Port2In', 'TrialEnd', 'Port3In', 'TrialEnd', 'Port4In', 'TrialEnd', 'Port5In', 'TrialEnd', 'Port6In', 'TrialEnd', 'Port7In', 'TrialEnd', 'Port8In', 'TrialEnd', 'Tup', 'MaxOutputReturn'},...
                'OutputActions', [io.SampleStimOn]);
            
            sma = AddState(sma, 'Name', 'MaxOutputReturn', ...
                'Timer', 0.01,...
                'StateChangeConditions', {'Tup', 'MaxOutput'},...
                'OutputActions', [io.SampleStimOn]);
            
            sma = AddState(sma, 'Name', 'TrialEnd', ...
                'Timer', 0.05,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'BNCState', 0});
            
        case 3          % yes_no_multistim

            % Determine trial-specific state matrix fields
            switch TrialTypes(currentTrial)
                case 1  % lick left
                   action.lickleft = 'Reward'; action.lickright = 'TimeOut'; io.Reward = io.LeftWater; action.sample = io.SampleStimOff;
                case 0  % lick right
                   action.lickleft = 'TimeOut'; action.lickright = 'Reward'; io.Reward = io.RightWater; action.sample = io.SampleStimOn;
            end
            
            sma = NewStateMatrix(); % Assemble state matrix
            % add bitcode here
            sma = get_yes_no_multistim_matrix(sma, S, io, action);
            
            
        case 4          % yes_no_multistim_delay
            
            % Determine trial-specific state matrix fields
            switch TrialTypes(currentTrial)
                case 1  % lick left
                   action.lickleft = 'Reward'; action.lickright = 'TimeOut'; io.Reward = io.LeftWater; action.sample = io.SampleStimOff;
                case 0  % lick right
                   action.lickleft = 'TimeOut'; action.lickright = 'Reward'; io.Reward = io.RightWater; action.sample = io.SampleStimOn;
            end
            
            sma = NewStateMatrix(); % Assemble state matrix
            sma = get_yes_no_multistim_delay_matrix(sma, S, io, action);
   
    end
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;         % this step takes a long time and variable (seem to wait for GUI to update, which takes a long time)
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        %%BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        
        earlyLick = (S.GUI.Lick_Max_YesNo_Del==4)&(any(ismember(RawEvents.States, [4 8])));
        BpodSystem.Data.earlyLick(currentTrial) = earlyLick;
        
        if S.GUI.Lick_Max_YesNo_Del==2
            programPulsePalSineWave([], [], 1, 'Init');
            BpodSystem.Pause = 1;
        end
        
        if S.GUI.Lick_Max_YesNo_Del == 3 || S.GUI.Lick_Max_YesNo_Del == 4
            UpdateYesNoPerfOutcomePlot(TrialTypes, BpodSystem.Data);
            
        end
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        
        BpodSystem.ProtocolSettings = S;
        SaveBpodProtocolSettings;
    end

    % Pause the protocol before starting if in Water-Valve-Calibration
%     if S.GUI.Lick_Max_YesNo_Del == 1
%         BpodSystem.Pause = 1;
%     end
    
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
end



function UpdateYesNoPerfOutcomePlot(TrialTypes, Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);

for x = 1:Data.nTrials
    
    if Data.TrialSettings(x).GUI.Lick_Max_YesNo_Del==3 || Data.TrialSettings(x).GUI.Lick_Max_YesNo_Del==4
        if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
            Outcomes(x) = 1;    % correct
        elseif ~isnan(Data.RawEvents.Trial{x}.States.NoResponse(1))
            Outcomes(x) = 2;    % no repsonse
        elseif ~isnan(Data.RawEvents.Trial{x}.States.TimeOut(1))
            Outcomes(x) = 0;    % error
            
        else
            Outcomes(x) = 3;    % others
        end
    else
        Outcomes(x) = 3;        % others
    end
    
end

        

YesNoPerfOutcomePlot(BpodSystem.GUIHandles.YesNoPerfOutcomePlot,Data.nTrials,'update',TrialTypes, BpodSystem.GUIHandles.DisplayNTrials, Outcomes, Data.earlyLick);

% YesNoPerfOutcomePlot(BpodSystem.GUIHandles.YesNoPerfOutcomePlot,BpodSystem.GUIHandles.DisplayNTrials,'next_trial',TrialTypes(currentTrial));
% YesNoPerfOutcomePlot(BpodSystem.GUIHandles.YesNoPerfOutcomePlot,BpodSystem.GUIHandles.DisplayNTrials,'init',2-TrialTypes);





function YesNoPerfOutcomePlot(ax, Ntrials, action, varargin)
global BpodSystem
sz = 15;

switch action
    case 'update'
        
        types = varargin{1};
        displayHand = varargin{2};
        outcomes = varargin{3};
        early = varargin{4};
        
        Ndisplay = str2double(get(displayHand, 'String'));
        
        toPlot = false(1, Ntrials);
        
        ind1 = max(1, Ntrials-Ndisplay+1);
        ind2 = Ntrials;
        
        toPlot(ind1:ind2) = true;
        
        miss = outcomes==0;
        hit  = outcomes==1;
        no   = outcomes==2;
        
        hold(ax, 'off');
        xdat = find(toPlot&hit);
        plot(ax, xdat, types(xdat)+1, 'g.', 'MarkerSize', sz); hold(ax, 'on');
        
        xdat = find(toPlot&miss);
        plot(ax, xdat, types(xdat)+1, 'r.', 'MarkerSize', sz);
        
        xdat = find(toPlot&no);
        plot(ax, xdat, types(xdat)+1, 'kx');
        
        
        
        
        xdat = find(toPlot&early);
        plot(ax, xdat, types(xdat)+1.25, 'b.', 'MarkerSize', sz);
        
        hitpct = 100.*sum(hit)./Ntrials;
        inds40 = max(1, Ntrials-40+1):Ntrials;
        hitpctrecent = 100.*sum(hit(inds40))./numel(inds40);
        
        left  = (BpodSystem.Data.TrialTypes==0);
        right = (BpodSystem.Data.TrialTypes==1);
        
        hitpctleft = 100.*sum(left&hit)./sum(left);
        hitpctright = 100.*sum(right&hit)./sum(right);
        
        set(BpodSystem.GUIHandles.hitpct, 'String', num2str(hitpct));
        set(BpodSystem.GUIHandles.hitpctrecent, 'String', num2str(hitpctrecent));
        set(BpodSystem.GUIHandles.hitpctright, 'String', num2str(hitpctright));
        set(BpodSystem.GUIHandles.hitpctleft, 'String', num2str(hitpctleft));
        set(BpodSystem.GUIHandles.numtrials, 'String', num2str(Ntrials));
        set(BpodSystem.GUIHandles.numrewards, 'String', num2str(sum(hit)));
        
        xlim(ax, [ind1 ind1+Ndisplay-1+5]);
        ylim(ax, [0 3]);
        
    case 'next_trial'
        currentType = varargin{1};
        displayHand = varargin{2};
        Ndisplay = str2double(get(displayHand, 'String'));
        ind1 = max(1, Ntrials-Ndisplay+1);
        ind2 = Ntrials;
        
        hold(ax, 'on');
        plot(ax, Ntrials, currentType+1, 'k.', 'MarkerSize', sz);
        xlim(ax, [ind1 ind1+Ndisplay-1+5]);
        
    case 'init'
%         currentType = varargin{1};
%         hold(ax, 'on');
%         plot(ax, Ntrials, currentType, 'k.');
        
        
end
set(ax, 'YTick', [0 1 2 3], 'YTickLabel', {''; 'Lick Right'; 'Lick Left'; ''});






function sma = get_yes_no_multistim_matrix(sma, S, io, action)
sma = AddState(sma, 'Name', 'TrigTrialStart', ...                       %: TrigTrialStart; output WSTtrig, 10 ms later go to SamplePeriod ()
    'Timer', 0.1,...
    'StateChangeConditions', {'Tup', 'PreSamplePeriod'},...
    'OutputActions', io.WSTrig);

sma = AddState(sma, 'Name', 'PreSamplePeriod', ...                      %: SamplePeriod - pole down, go to ResponseCue () after SamplePeriod
    'Timer', S.GUI.PreSamplePeriod,...
    'StateChangeConditions', {'Tup', 'SamplePeriod1'},...
    'OutputActions', {});



sma = AddState(sma, 'Name', 'SamplePeriod1', ...                         %: SamplePeriod1 - Lick either direction and go to EarlyLickSample() otherwise SamplePeriod2()
    'Timer', 0.15,...
    'StateChangeConditions', {'Tup', 'SamplePeriod2'},...
    'OutputActions', [action.sample io.Alarm]);

sma = AddState(sma, 'Name', 'SamplePeriod2', ...                         %: SamplePeriod2 - Lick either direction and go to EarlyLickSample() otherwise SamplePeriod3()
    'Timer', S.GUI.SamplePeriod-0.3,...
    'StateChangeConditions', {'Tup', 'SamplePeriod3'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'SamplePeriod3', ...                         %: SamplePeriod3 - Lick either direction and go to EarlyLickSample() otherwise Delay()
    'Timer', 0.15,...
    'StateChangeConditions', {'Tup', 'ResponseCue'},...
    'OutputActions', [io.Alarm]);


sma = AddState(sma, 'Name', 'ResponseCue', ...                          %: ResponseCue - Play response cue, pole stays down, go to AnswerPeriod ()
    'Timer', 0.1,...
    'StateChangeConditions', {'Tup', 'AnswerPeriod'},...
    'OutputActions', [io.Cue]);
sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         %: AnswerPeriod - Go to either Reward () or Timeout () depending on lick direction, otherwise go to NoResponse (10)
    'Timer', S.GUI.AnswerPeriod,...
    'StateChangeConditions', {'Port1In', action.lickleft, 'Port2In', action.lickright, 'Tup', 'NoResponse'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'Reward', ...                               %: Reward - Give reward and go to RewardConsumption () after WaterValveTime
    'Timer', S.GUI.WaterValveTime,...
    'StateChangeConditions', {'Tup', 'RewardConsumption'},...
    'OutputActions', [io.Reward]);
sma = AddState(sma, 'Name', 'RewardConsumption', ...                    %: RewardConsumption - Go to StopLicking () after ConsumptionPeriodTime
    'Timer', S.GUI.ConsumptionPeriod,...
    'StateChangeConditions', {'Tup', 'StopLicking'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'NoResponse', ...                           %: NoResponse - Go to StopLicking ()
    'Timer', 0.002,...
    'StateChangeConditions', {'Tup', 'TimeOut'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'TimeOut', ...                              %: Timeout - Go to StopLicking () after TimeOut
    'Timer', S.GUI.TimeOut,...
    'StateChangeConditions', {'Tup', 'StopLicking'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'StopLicking', ...                          %: StopLicking - Go to StopLickingReturn () if lick, otherwise go to TrialEnd (11) after StopLickingPeriod
    'Timer', S.GUI.StopLickingPeriod,...
    'StateChangeConditions', {'Port1In', 'StopLickingReturn','Port3In', 'StopLickingReturn','Tup', 'TrialEnd'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    %: StopLickingReturn - Go back to StopLicking () after 10 ms
    'Timer', 0.01,...
    'StateChangeConditions', {'Tup', 'StopLicking'},...
    'OutputActions',{});
sma = AddState(sma, 'Name', 'TrialEnd', ...                             %: TrialEnd - Exit after 50 ms
    'Timer', 0.05,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {});






function sma = get_yes_no_multistim_delay_matrix(sma, S, io, action)
sma = AddState(sma, 'Name', 'TrigTrialStart', ...                       %: TrigTrialStart; 10 ms later go to Sample
    'Timer', 0.1,...
    'StateChangeConditions', {'Tup', 'PreSamplePeriod'},...
    'OutputActions', io.WSTrig);
sma = AddState(sma, 'Name', 'PreSamplePeriod', ...                      %: PreSamplePeriod - pole down, go to ResponseCue () after SamplePeriod
    'Timer', S.GUI.PreSamplePeriod,...
    'StateChangeConditions', {'Tup', 'SamplePeriod1'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'SamplePeriod1', ...                         %: SamplePeriod1 - Lick either direction and go to EarlyLickSample() otherwise SamplePeriod2()
    'Timer', 0.15,...
    'StateChangeConditions', {'Port1In','EarlyLickSample','Port2In','EarlyLickSample','Tup', 'SamplePeriod2'},...
    'OutputActions', [action.sample io.Alarm]);

sma = AddState(sma, 'Name', 'SamplePeriod2', ...                         %: SamplePeriod2 - Lick either direction and go to EarlyLickSample() otherwise SamplePeriod3()
    'Timer', S.GUI.SamplePeriod-0.3,...
    'StateChangeConditions', {'Port1In','EarlyLickSample','Port2In','EarlyLickSample','Tup', 'SamplePeriod3'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'SamplePeriod3', ...                         %: SamplePeriod3 - Lick either direction and go to EarlyLickSample() otherwise Delay()
    'Timer', 0.15,...
    'StateChangeConditions', {'Tup', 'DelayPeriod'},...
    'OutputActions', [io.Alarm]);
sma = AddState(sma, 'Name', 'EarlyLickSample', ...                      %: EarlyLickSample - Play alarm, restart SamplePeriod () after 50 ms
    'Timer', 0.05,...
    'StateChangeConditions', {'Tup', 'SamplePeriod2'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'DelayPeriod', ...                          %: Delay - Lick either direction and go to EarlyLickDelay (), otherwise go to ResponseCue ().
    'Timer', S.GUI.DelayPeriod,...
    'StateChangeConditions', {'Port1In','EarlyLickDelay','Port2In','EarlyLickDelay','Tup', 'ResponseCue'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'EarlyLickDelay', ...                       %: EarlyLickDelay - Play alarm, restart Delay () after 50 ms
    'Timer', 0.05,...
    'StateChangeConditions', {'Tup', 'DelayPeriod'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'ResponseCue', ...                          %: ResponseCue - Play response cue, go to AnswerPeriod () after 100 ms
    'Timer', 0.1,...
    'StateChangeConditions', {'Tup', 'AnswerPeriod'},...
    'OutputActions', io.Cue);
sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         %: AnswerPeriod - Go to either Reward () or Timeout () depending on lick direction, otherwise go to NoResponse ()
    'Timer', S.GUI.AnswerPeriod,...
    'StateChangeConditions', {'Port1In', action.lickleft, 'Port2In', action.lickright, 'Tup', 'NoResponse'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'Reward', ...                               %: Reward - Give reward and go to RewardConsumption () after WaterValveTime
    'Timer', S.GUI.WaterValveTime,...
    'StateChangeConditions', {'Tup', 'RewardConsumption'},...
    'OutputActions', io.Reward);
sma = AddState(sma, 'Name', 'RewardConsumption', ...                    %: RewardConsumption - Go to StopLicking () after ConsumptionPeriodTime
    'Timer', S.GUI.ConsumptionPeriod,...
    'StateChangeConditions', {'Tup', 'StopLicking'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'NoResponse', ...                           %: NoResponse - Go to StopLicking ()
    'Timer', 0.002,...
    'StateChangeConditions', {'Tup', 'StopLicking'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'TimeOut', ...                              %: Timeout - Go to StopLicking () after TimeOut
    'Timer', S.GUI.TimeOut,...
    'StateChangeConditions', {'Tup', 'StopLicking'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'StopLicking', ...                          %: StopLicking - Go to StopLickingReturn if lick, otherwise go to TrialEnd () after StopLickingPeriod
    'Timer', S.GUI.StopLickingPeriod,...
    'StateChangeConditions', {'Port1In', 'StopLickingReturn','Port2In', 'StopLickingReturn','Tup', 'TrialEnd'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    %: StopLickingReturn - Go back to StopLicking () after 10 ms
    'Timer', 0.01,...
    'StateChangeConditions', {'Tup', 'StopLicking'},...
    'OutputActions',{});
sma = AddState(sma, 'Name', 'TrialEnd', ...                             %: TrialEnd - Exit after 50 ms
    'Timer', 0.05,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {});










