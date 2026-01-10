%% 小场景（50m）：需要修改PRF、SampleRate、PulseWidth
%% 必须保证在PulseWidth时间内至少采到1个点，所以采样率一定要大于 1 / PulseWidth
%% 采样率：1e10
clc;
clear;
close all;
SampleRate = 1e10;
CentralFrequency = 4e5;

%% 目标的三种位置
Front = [50;0;0];
Angle_30 = [40;30;0];
Angle_60 = [30;40;0];
Angle_80 = [49.2407;8.6806;0];
Angle_90 = [1;50;0];

%% 基本系统参数配置
waveform = phased.RectangularWaveform('PulseWidth',1e-7, ...
    'PRF',1e5,'OutputFormat','Pulses','NumPulses',1);
waveform.SampleRate = SampleRate;

antenna = phased.IsotropicAntennaElement('FrequencyRange',[1 1e10]);

array = phased.ULA('NumElements',2,'ElementSpacing', ...
    0.5*physconst('LightSpeed') / CentralFrequency, ...
    'Element',antenna);

target = phased.RadarTarget('Model','Nonfluctuating','MeanRCS',0.5, ...
    'PropagationSpeed',physconst('LightSpeed'),'OperatingFrequency',CentralFrequency);

antennaplatform = phased.Platform('InitialPosition',[0;0;0],'Velocity',[0;0;0]);
targetplatform = phased.Platform('InitialPosition',Angle_60, ...
    'Velocity',[0;0;0]);


[~,~] = rangeangle(targetplatform.InitialPosition, ...
    antennaplatform.InitialPosition);

Pd = 0.9;
Pfa = 1e-6;
numpulses = 1;
SNR = albersheim(Pd,Pfa,10);


maxrange = 1.5e4;
lambda = physconst('LightSpeed')/target.OperatingFrequency;
tau = waveform.PulseWidth;
Ts = 290;
rcs = 0.5;
Gain = 20;
dbterm = db2pow(SNR - 2*Gain);
Pt = (4*pi)^3*physconst('Boltzmann')*Ts/tau/rcs/lambda^2*maxrange^4*dbterm;

%% 各种设备元件
transmitter = phased.Transmitter('PeakPower',5e2, ... % 雷达发射机峰值功率
    'Gain',20,'LossFactor',0, ...
    'InUseOutputPort',true,'CoherentOnTransmit',true);



radiator = phased.Radiator('Sensor',antenna,...
    'PropagationSpeed',physconst('LightSpeed'),'OperatingFrequency',CentralFrequency);  % radiator的工作频率指的就是传输信号的中心频率


collector = phased.Collector('Sensor',array ,... % 没有问题，'sensor'既可以是单天线，也可以是天线阵列
    'PropagationSpeed',physconst('LightSpeed'),'Wavefront','Plane', ... 
    'OperatingFrequency',CentralFrequency);

receiver = phased.ReceiverPreamp('Gain',20,'NoiseFigure',2, ... % 名称：preamp  pre：前置  amp：放大
    'ReferenceTemperature',290,'SampleRate',SampleRate, ...
    'EnableInputPort',true,'SeedSource','Property','Seed',1e3);


channel = phased.FreeSpace(...  % 自由空间不包含空气，是一种理想介质
    'PropagationSpeed',physconst('LightSpeed'), ...
    'OperatingFrequency',CentralFrequency,'TwoWayPropagation',false, ...
    'SampleRate',SampleRate);


T = 1/waveform.PRF;

txpos = antennaplatform.InitialPosition;

rxsig = zeros(round(waveform.SampleRate*T),2);


%% sig4~sig7都是复数
% sig1就是普通的基带信号
% sig2和sig3完全一样，功率比sig1放大了2000倍
% channel这一步，信号会变成复信号，
% 目标位于5km处，计算可得，目标返回到达的时间位于第33个采样点处，和sig7 8结果完全一致
% 
t = unigrid(0,1/receiver.SampleRate,T,'[)'); % t的长度为什么是200：采样率是1e6，PRF是5e3。1秒钟采1e6个点，1秒钟又有5e3个脉冲，两者一除等于200，即一个脉冲周期有200个采样点
    % Update the target position
    [tgtpos,tgtvel] = targetplatform(T);
    % Get the range and angle to the target
    [tgtrng,tgtang] = rangeangle(tgtpos,txpos);
    % Generate the pulse
    sig = waveform();
    sig1 = sig;
    % sig1_complex = sig1 .* exp(1j*2*pi*1e5*t');
    % Transmit the pulse. Output transmitter status
    [sig,txstatus] = transmitter(sig);
    sig2 = sig;
    % Radiate the pulse toward the target
    sig = radiator(sig,tgtang);
    sig3 = sig;
    % Propagate the pulse to the target in free space
    sig = channel(sig,txpos,tgtpos,[0;0;0],tgtvel);
    sig4 = abs(sig);
    sig4_complex = sig;
    % Reflect the pulse off the target
    sig = target(sig);
    sig5 = abs(sig);
    sig5_complex = sig;
    % Propagate the echo to the antenna in free space
    sig = channel(sig,tgtpos,txpos,tgtvel,[0;0;0]);
    sig6 = abs(sig);
    sig6_complex = sig;
    % Collect the echo from the incident angle at the antenna
    sig = collector(sig,tgtang);  % 在这一步，会将到达角带入接收天线方向图，实现角度选择性增益 
    sig7 = abs(sig);
    sig7_complex = sig;
    % Receive the echo at the antenna when not transmitting
    rxsig = receiver(sig,~txstatus);
    temp = receiver(sig,~txstatus); % temp是复数
    sig8 = abs(temp);


rxsig = pulsint(rxsig(:,1) + rxsig(:,2),'noncoherent');

rangegates = (physconst('LightSpeed')*t)/2;
plot(rangegates/1e3,rxsig)
hold on
xlabel('range (km)')
ylabel('Power')
xline(tgtrng/1e3,'r')
hold off

