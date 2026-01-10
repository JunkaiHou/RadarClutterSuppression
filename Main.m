%% Main
clc;
clear;
close all;


%% 基础配置 按照Nature论文要求 相同带宽、相同脉冲宽度的两个线性调频信号

% 说明：waveform是基带信号，在通过了phased.Radiator里面的OperatingFrequency（信号中心频率）之后，被调制到高频，才能通过天线阵列发射出去

% 定义Chirp波形
pulseWidth = 1e-6; % 脉冲宽度
PRF = 5e3; % 脉冲重复频率
sweepBandwidth = 1e6; % Chirp带宽
fs = 1e6; % 采样率

% 使用线性调频信号
waveform = phased.LinearFMWaveform('PulseWidth', pulseWidth, ...
    'PRF', PRF, 'SampleRate', fs, ...
    'SweepBandwidth', sweepBandwidth, 'OutputFormat', 'Pulses', 'NumPulses', 1);

antenna = phased.IsotropicAntennaElement('FrequencyRange',[1e9 10e9]);

TxAntennaNum = 2;
RxAntennaNum = 2;
elementSpacing = 0.5 * (physconst('LightSpeed') / 4e9); % 元素间距  之前推导过：间距为半波长就可以

% 创建发射天线阵列
txArray = phased.ULA('NumElements', TxAntennaNum, 'ElementSpacing', elementSpacing);
txArray.Element = antenna; % 使用之前定义的全向天线单元

% 创建接收天线阵列
rxArray = phased.ULA('NumElements', RxAntennaNum, 'ElementSpacing', elementSpacing);
rxArray.Element = antenna;

%% 配置蝙蝠飞行过程中的目标 目标1是目标探测物体（如猎物） 目标2是杂波反射源（如树木）
% 现有第一个目标
target1 = phased.RadarTarget('Model','Nonfluctuating',...
    'MeanRCS',1, ... % MeanRCS的单位是平方米
    'PropagationSpeed',physconst('LightSpeed'), ...
    'OperatingFrequency',4e9, ...
    'EnablePolarization',false);
    %  %  OperatingFrequency 在 phased.RadarTarget 中并不是指目标本身的频率，而是指雷达系统与目标交互时的信号频率
    

targetplatform1 = phased.Platform('InitialPosition',[5000; 0; 0], ... %设定在正前方(X轴）
    'Velocity',[-15; -10; 0]);

% 添加第二个目标  Swerling II 模型适合建模树木（这个模型假设目标的散射特性是变化的，适用于对具有一定反射率和散射特性的非静态目标进行建模，如树木等自然环境中的目标）
target2 = phased.RadarTarget('Model','Swerling2',...
    'MeanRCS',5, ...  % 树木rcs一般在5平方米左右
    'PropagationSpeed',physconst('LightSpeed'),...
    'OperatingFrequency',4e9,...
    'EnablePolarization',false);
    
    

targetplatform2 = phased.Platform('InitialPosition',[4000; 3000; 0], ...  %树木静止不动
    'Velocity',[0; 0; 0]);

antennaplatform = phased.Platform('InitialPosition',[0;0;0],'Velocity',[0;0;0]);  %天线的位置是坐标原点


%% 一些其他无关紧要的参数
Pd = 0.9;
Pfa = 1e-6;
numpulses = 10;
SNR = albersheim(Pd,Pfa,10);


maxrange = 1.5e4;
lambda = physconst('LightSpeed') / 4e9;
tau = waveform.PulseWidth;
Ts = 290;
rcs = 0.5;
Gain = 20;
dbterm = db2pow(SNR - 2*Gain);
Pt = (4*pi)^3*physconst('Boltzmann')*Ts/tau/rcs/lambda^2*maxrange^4*dbterm;

%% 配置收发端设备 基带的LFM信号通过radiator之后，被调制到高频发射出去 Nature文章中的雷达采用17.5MHz和22.5MHz
transmitter = phased.Transmitter('PeakPower',50e3,'Gain',20,'LossFactor',0, ...
    'InUseOutputPort',true,'CoherentOnTransmit',true);

radiator1 = phased.Radiator('Sensor',txArray,...
    'PropagationSpeed',physconst('LightSpeed'),'OperatingFrequency',4e9);

radiator2 = phased.Radiator('Sensor',txArray,...
    'PropagationSpeed',physconst('LightSpeed'),'OperatingFrequency',5e9);

collector = phased.Collector('Sensor',rxArray,...
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
rxsig = zeros(waveform.SampleRate*T, numpulses, 2); % 为两个目标预留信号


%% 开始模拟传播过程  

% 循环处理每个脉冲
for n = 1:numpulses
    % 更新目标1的位置和角度
    [tgtpos1, tgtvel1] = targetplatform1(T);
    [tgtrng1, tgtang1] = rangeangle(tgtpos1, txpos);
    
    % 更新目标2的位置和角度
    [tgtpos2, tgtvel2] = targetplatform2(T);
    [tgtrng2, tgtang2] = rangeangle(tgtpos2, txpos);
    
    % 生成波形
    sig = waveform();
    % 通过发射机发射波形
    [sig, txstatus] = transmitter(sig);
    
    % 处理第一个目标的回波
    sig1 = radiator1(sig, tgtang1) + radiator2(sig, tgtang1);              % 朝第一个目标辐射
    sig1 = channel(sig1, txpos, tgtpos1, [0;0;0], tgtvel1);                % 传输到目标1
    sig1 = target1(sig1);                                                  % 目标1反射
    sig1 = channel(sig1, tgtpos1, txpos, tgtvel1, [0;0;0]);                % 传输回接收端
    sig1 = collector(sig1, tgtang1);                                       % 接收器收集信号
    rxsig(:, n, 1) = mean(receiver(sig1, ~txstatus),2);                    % 接收器接收第一个目标信号
    
    % 处理第二个目标的回波
    sig2 = radiator1(sig, tgtang2) + radiator2(sig, tgtang2);              % 朝第二个目标辐射
    sig2 = channel(sig2, txpos, tgtpos2, [0;0;0], tgtvel2);                % 传输到目标2
    sig2 = target2(sig2 , true);                                             % 目标2反射：参数项要加上true 表示目标RCS时变（swerling模型都要加第二个参数项）
    sig2 = channel(sig2, tgtpos2, txpos, tgtvel2, [0;0;0]);                % 传输回接收端
    sig2 = collector(sig2, tgtang2);                                       % 接收器收集信号
    rxsig(:, n, 2) = mean(receiver(sig2, ~txstatus),2);                    % 接收器接收第二个目标信号
end

% 对两个目标的回波信号分别进行非相干积累
rxsig1 = pulsint(rxsig(:,:,1),'noncoherent');
rxsig2 = pulsint(rxsig(:,:,2),'noncoherent');

% 绘制两个目标的回波信号
t = unigrid(0, 1/receiver.SampleRate, T, '[)');  % unigrid 的功能是生成一个从起始值到结束值的均匀间隔向量，常用于时间序列数据的处理  [)表示左闭右开
rangegates = (physconst('LightSpeed') * t) / 2;

plot(rangegates/1e3, rxsig1)
hold on
plot(rangegates/1e3, rxsig2)
xline([tgtrng1/1e3, tgtrng1/1e3], 'r')
xline([tgtrng2/1e3, tgtrng2/1e3], 'g')
xlabel('Range (km)')
ylabel('Power')
legend('Target 1', 'Target 2')
hold off

%% 后向投影成像
% 
% 
% %%BP成像
% % 设定成像网格的大小和分辨率
% xlim = [0, 100]; % 水平范围（米）
% ylim = [0, 100];   % 垂直范围（米）
% gridResolution = 0.5; % 每个像素的大小（米）
% 
% % 创建成像网格
% [xGrid, yGrid] = meshgrid(xlim(1):gridResolution:xlim(2), ylim(1):gridResolution:ylim(2));
% imageIntensity = zeros(size(xGrid));
% 
% % 计算成像网格上每个点的距离
% for n = 1:numpulses
%     % 更新目标位置和角度
%     [tgtpos1, ~] = targetplatform1(T); % 获取目标1位置
%     [tgtrng1, ~] = rangeangle(tgtpos1, txpos);
%     [tgtpos2, ~] = targetplatform2(T); % 获取目标2位置
%     [tgtrng2, ~] = rangeangle(tgtpos2, txpos);
% 
%     % 接收回波信号
%     sig1 = rxsig(:,n,1); % 目标1的接收信号
%     sig2 = rxsig(:,n,2); % 目标2的接收信号
% 
%     % 对成像网格上的每个点进行BP处理
%     for ix = 1:size(xGrid, 1)
%         for iy = 1:size(xGrid, 2)
%             % 计算每个网格点与雷达位置的距离
%             gridPoint = [xGrid(ix, iy); yGrid(ix, iy); 0];
%             range1 = norm(gridPoint - txpos); % 到目标1的距离
%             range2 = norm(gridPoint - tgtpos1); % 到目标2的距离
% 
%             % 将接收的回波信号与相应的距离对应并进行叠加
%             delayIndex1 = round(range1 / (physconst('LightSpeed') / receiver.SampleRate));
%             delayIndex2 = round(range2 / (physconst('LightSpeed') / receiver.SampleRate));
% 
%             if delayIndex1 > 0 && delayIndex1 <= length(sig1)
%                 imageIntensity(ix, iy) = imageIntensity(ix, iy) + abs(sig1(delayIndex1));
%             end
% 
%             if delayIndex2 > 0 && delayIndex2 <= length(sig2)
%                 imageIntensity(ix, iy) = imageIntensity(ix, iy) + abs(sig2(delayIndex2));
%             end
%         end
%     end
% end
% 
% % 绘制成像结果
% figure;
% imagesc(xlim, ylim, 10*log10(imageIntensity)); % 转为dB强度显示
% colorbar;
% xlabel('X (m)');
% ylabel('Y (m)');
% title('目标成像 - BP成像结果');

