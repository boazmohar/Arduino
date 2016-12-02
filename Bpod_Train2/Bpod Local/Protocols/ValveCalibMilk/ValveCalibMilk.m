function ValveCalibMilk()
global BpodSystem
S = struct;
S.GUI.ValveTime = 0.1;
S.GUI.ValveNumber = 0;
S.GUI.nValves = 100;
BpodParameterGUI('init', S);
TrialTypes = ones(1,100);
BpodSystem.Status.Pause = 1;
HandlePauseCondition;
for currentTrial = 1:100
    S = BpodParameterGUI('sync', S);
    if S.GUI.ValveNumber == 0
        ValveID = 1;
    elseif S.GUI.ValveNumber == 1
        ValveID = 2;
    end
    sma = NewStateMatrix();
    for y = 1:S.GUI.nValves
        sma = AddState(sma, 'Name', ['PulseValve' num2str(y)], ...
            'Timer', S.GUI.ValveTime ,...
            'StateChangeConditions', ...
            {'Tup', ['Delay' num2str(y)]},...
            'OutputActions', {'WireState', ValveID});
        if y < S.GUI.nValves
            sma = AddState(sma, 'Name', ['Delay' num2str(y)], ...
                'Timer', 0.2,...
                'StateChangeConditions', ...
                {'Tup', ['PulseValve' num2str(y+1)]},...
                'OutputActions', {});
        else
            sma = AddState(sma, 'Name', ['Delay' num2str(y)], ...
                'Timer', 0.2,...
                'StateChangeConditions', ...
                {'Tup', 'exit'},...
                'OutputActions', {});
        end
    end
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents);
    BpodSystem.Data.TrialSettings(currentTrial) = S;
    SaveBpodSessionData;
    BpodSystem.Status.Pause = 1;
    HandlePauseCondition;
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0
            return
    end
end
