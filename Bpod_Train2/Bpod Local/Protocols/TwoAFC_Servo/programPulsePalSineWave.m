function programPulsePalSineWave(hObject, ~, chan, field)

global S;


if ~isempty(field)
   if strcmp(field, 'StimPower')
       S.GUI.StimPower = str2double(get(hObject, 'String'));
   elseif strcmp(field, 'MaxPower')
       S.GUI.MaxPower = str2double(get(hObject, 'String'));
   elseif strcmp(field, 'StimLength')
       S.GUI.StimLength = str2double(get(hObject, 'String'));
   end
end


RampDownTime = 0.2;

addpath(genpath('C:\PulsePal\MATLAB'));
pp.dt = 0.001;
pp.f = 10;
pp.tend = S.GUI.StimLength+RampDownTime;
pp.fs = 1./pp.dt;
pp.x = pp.dt:pp.dt:pp.tend;

voltage = [0 0.10 0.25 0.50  0.75  1.00 2.00 3.00 4.00  4.25  4.50  4.75  4.90  5.00];
power   = [0 0.03 0.17 0.39  0.61  0.81 1.58 2.23 2.74  2.88  3.04  3.19  3.25  3.30];
power = (power./power(end)).*S.GUI.MaxPower;

pp.vmax = interp1(power, voltage, S.GUI.StimPower, 'Cubic', S.GUI.MaxPower);
pp.wave = pp.vmax*(0.5 + 0.5.*sin(2*pi*pp.x.*pp.f));

% pp.wave = pp.vmax*ones(size(pp.x));  %For testing constant illumination

envelope = ones(size(pp.x));
rampstartind = find(pp.x>S.GUI.StimLength, 1, 'first');
rampendind = numel(pp.x);

envelope(rampstartind:rampendind) = linspace(1, 0, rampendind-rampstartind+1);
pp.wave = pp.wave.*envelope;


chanMF = 2;








PulsePal;
ProgramPulsePalParam(chan, 14 , chan); % Sets output channel 1 to use custom train 1
ProgramPulsePalParam(chan, 12 , chan); % Sets output channel 1 to respond to triggers on trigger channel 1
SendCustomWaveform(chan, pp.dt, pp.wave); % Uploads sine waveform. Samples are played at 1 khz.

ProgramPulsePalParam(chanMF, 1, 0); %IsBiphasic
ProgramPulsePalParam(chanMF, 2, 4); %Phase1Voltage
ProgramPulsePalParam(chanMF, 4, 0.01); %Phase1Duration
ProgramPulsePalParam(chanMF, 7, 0.09); %InterPulseInterval
ProgramPulsePalParam(chanMF, 10, 3); %PulseTrainDuration
ProgramPulsePalParam(chanMF, 11, 0); %PulseTrainDelay
ProgramPulsePalParam(chanMF, 12, 0); %LinkedToTriggerCh2
ProgramPulsePalParam(chanMF, 13, 1); %LinkedToTriggerCh2

SyncPulsePalParams;




EndPulsePal();






