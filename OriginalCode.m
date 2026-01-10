clc;
clear;
close all;
waveform = phased.RectangularWaveform('PulseWidth',1e-5, ...
    'PRF',5e3,'OutputFormat','Pulses','NumPulses',1);

antenna = phased.IsotropicAntennaElement('FrequencyRange',[1e9 10e9]);

target = phased.RadarTarget('Model','Nonfluctuating','MeanRCS',0.5, ...
    'PropagationSpeed',physconst('LightSpeed'),'OperatingFrequency',4e9);

antennaplatform = phased.Platform('InitialPosition',[0;0;0],'Velocity',[0;0;0]);
targetplatform = phased.Platform('InitialPosition',[4000; 3000; 0], ...
    'Velocity',[-15;-10;0]);


[tgtrng,tgtang] = rangeangle(targetplatform.InitialPosition, ...
    antennaplatform.InitialPosition);

Pd = 0.9;
Pfa = 1e-6;
numpulses = 10;
SNR = albersheim(Pd,Pfa,10);


maxrange = 1.5e4;
lambda = physconst('LightSpeed')/target.OperatingFrequency;
tau = waveform.PulseWidth;
Ts = 290;
rcs = 0.5;
Gain = 20;
dbterm = db2pow(SNR - 2*Gain);
Pt = (4*pi)^3*physconst('Boltzmann')*Ts/tau/rcs/lambda^2*maxrange^4*dbterm;


transmitter = phased.Transmitter('PeakPower',50e3,'Gain',20,'LossFactor',0, ...
    'InUseOutputPort',true,'CoherentOnTransmit',true);



radiator = phased.Radiator('Sensor',antenna,...
    'PropagationSpeed',physconst('LightSpeed'),'OperatingFrequency',4e9);
collector = phased.Collector('Sensor',antenna,...
    'PropagationSpeed',physconst('LightSpeed'),'Wavefront','Plane', ...
    'OperatingFrequency',4e9);



receiver = phased.ReceiverPreamp('Gain',20,'NoiseFigure',2, ...
    'ReferenceTemperature',290,'SampleRate',1e6, ...
    'EnableInputPort',true,'SeedSource','Property','Seed',1e3);


channel = phased.FreeSpace(...
    'PropagationSpeed',physconst('LightSpeed'), ...
    'OperatingFrequency',4e9,'TwoWayPropagation',false, ...
    'SampleRate',1e6);


T = 1/waveform.PRF;

txpos = antennaplatform.InitialPosition;

rxsig = zeros(waveform.SampleRate*T,numpulses);


%% 各元器件说明
% transmitter用于控制信号发射功率，而radiator是实际起到发射信号作用的装置

for n = 1:numpulses
    % Update the target position
    [tgtpos,tgtvel] = targetplatform(T);
    % Get the range and angle to the target
    [tgtrng,tgtang] = rangeangle(tgtpos,txpos);
    % Generate the pulse
    sig = waveform();
    % Transmit the pulse. Output transmitter status
    [sig,txstatus] = transmitter(sig);
    % Radiate the pulse toward the target
    sig = radiator(sig,tgtang);
    % Propagate the pulse to the target in free space
    sig = channel(sig,txpos,tgtpos,[0;0;0],tgtvel);
    % Reflect the pulse off the target
    sig = target(sig);
    % Propagate the echo to the antenna in free space
    sig = channel(sig,tgtpos,txpos,tgtvel,[0;0;0]);
    % Collect the echo from the incident angle at the antenna
    sig = collector(sig,tgtang);
    % Receive the echo at the antenna when not transmitting
    rxsig(:,n) = receiver(sig,~txstatus);
    temp = receiver(sig,~txstatus);
end
%% 

rxsig = pulsint(rxsig,'noncoherent');
figure(1)
t = unigrid(0,1/receiver.SampleRate,T,'[)');
rangegates = (physconst('LightSpeed')*t)/2;
plot(rangegates/1e3,rxsig)
hold on
xlabel('range (km)')
ylabel('Power')
xline(tgtrng/1e3,'r')
hold off

figure(2)
imagesc(rxsig');
title('range plot');
colorbar;


