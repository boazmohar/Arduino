function  moveZaberMotors(tType)
global BpodSystem motors_properties motors;


motor_param = makeStructureFromGUI(BpodSystem.GUIHandles.ParameterGUI);
rightPos  = motor_param.YesPosition;
leftPos = motor_param.NoPosition;
halfpoint = abs(round(abs(rightPos-leftPos)/2)) + min(leftPos,rightPos);
if tType == 1
    position = leftPos;
else
    position = rightPos;
end

tic
move_absolute_sequence(motors,{halfpoint,position},1);
movetime = toc;
if movetime<motor_param.MotorMoveTime % Should make this min-ITI a SoloParamHandle
     pause(motor_param.MotorMoveTime-movetime); %4
end


function motor_param = makeStructureFromGUI(ParameterGUI)

p = cellfun(@(x) strcmp(x,'YesPosition'),ParameterGUI.ParamNames);
motor_param.YesPosition = ParameterGUI.LastParamValues(p);

p = cellfun(@(x) strcmp(x,'NoPosition'),ParameterGUI.ParamNames);
motor_param.NoPosition = ParameterGUI.LastParamValues(p);

p = cellfun(@(x) strcmp(x,'MotorMoveTime'),ParameterGUI.ParamNames);
motor_param.MotorMoveTime = ParameterGUI.LastParamValues(p);






