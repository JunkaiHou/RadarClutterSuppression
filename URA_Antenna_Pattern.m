clc;
clear;
close all;
%% URA代表均匀矩形面阵列

c = physconst('LightSpeed');
fc = 9e9;
lambda = c/fc;
antenna1 = phased.ShortDipoleAntennaElement('AxisDirection','Z');
antenna2 = phased.ShortDipoleAntennaElement('AxisDirection','X');
array = phased.NRRectangularPanelArray('ElementSet', ...
        {antenna1, antenna2},'Size',[4, 4, 2, 2],'Spacing', ...  %[4, 4, 2, 2] 表示这个阵列的布局是 4x4 的大矩形单元，其中每个单元内部包含 2x2 的小单元。
        [0.5*lambda, 0.5*lambda,3*lambda, 3*lambda]); %设置各单元之间的间距。[0.5*lambda, 0.5*lambda] 表示小单元之间的间距为半波长（lambda 是波长），[3*lambda, 3*lambda] 表示大单元之间的间距为 3 倍波长。
figure(1);
pattern(array,fc,'ShowArray',true)

figure(2);
azimuthAngles = -180:180;
pattern(array,fc,azimuthAngles,0,'Type', 'directivity');