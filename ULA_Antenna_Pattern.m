%% 用phased.ULA设定好天线阵列之后，对不同频率的天线方向图就已经确定，和申报书中的天线方向图是一摸一样的
clc;
clear;
close all;
% 设置频率范围
frequency = [1e9,1.5e9,3e9,4e9]; % 各个频率（1 GHz, 1.5 GHz, 3 GHz, 4 GHz）
%frequencies = 17.5e6; % 各个频率（1 GHz, 1.5 GHz, 3 GHz, 4 GHz）
% 设置天线
antenna = phased.IsotropicAntennaElement('FrequencyRange', [0.3, 1e20]);

% 创建一个均匀线性阵列 (ULA) 天线，设置天线元件和元素间距
array = phased.ULA('Element', antenna, 'NumElements', 5, ...
    'ElementSpacing', 0.5 * physconst('LightSpeed') / 4e9);

%% 画二维方向图
% 设置角度范围
azimuthAngles = -180:180; % 方位角

% 绘制不同频率下的天线方向图
figure(1);


for k = 1:length(frequency)
    % 计算和绘制在每个频率下的方向图
    pattern(array, frequency(k), azimuthAngles, 0, 'Type', 'directivity');  % 'directivity'：表示绘制天线或阵列的指向性
        %'PlotStyle', 'overlay'); % 'overlay'：表示叠加模式，即将所有频率的方向图绘制在同一张图中
    
    hold on;

end

legend();
xlabel('Azimuth Angle (°)');
ylabel('Directivity (dB)');
title('Antenna Radiation Pattern at Different Frequencies');
hold off;


%% 画三维方向图
figure(2);
for i = 1:length(frequency)
    pattern(array,frequency(k),'ShowArray',true);
    hold on;
end

legend();
hold off;

