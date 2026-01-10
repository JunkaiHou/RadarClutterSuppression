clc;
clear all;
close all;
%% AWR（高频）64点，IWR（低频）256点
%% 比较一条线上的
Data1 = load("D:\BUPT_Windows\北京市自然科学基金\数据记录\AWR\AWR-MATLAB-一条线上.mat");
Data2 = load("D:\BUPT_Windows\北京市自然科学基金\数据记录\IWR\IWR一条线上.mat");
XLine = Data2.meas.RangeGrid;
Data1.meas.RangeProfile= interp1(Data1.meas.RangeGrid,Data1.meas.RangeProfile,XLine);
figure(1);
plot(XLine,Data1.meas.RangeProfile,'Color','blue','LineStyle','-','LineWidth',2);
xlabel('Range (m)');
ylabel('Power (dB)');
hold on;
plot(XLine,Data2.meas.RangeProfile,'Color','red','LineStyle','--','LineWidth',2);
title('One Line Compare on Dual-Frequency');
legend('AWR1642(High Frequency)','IWR6843(Low Frequency)');
hold off;

%% 比较两个角度
Data3 = load("D:\BUPT_Windows\北京市自然科学基金\数据记录\AWR\两个角度.mat");
Data4 = load("D:\BUPT_Windows\北京市自然科学基金\数据记录\IWR\IWR两个角度.mat");
Xaxis = Data4.meas.RangeGrid;
Data3.meas.RangeProfile= interp1(Data3.meas.RangeGrid,Data3.meas.RangeProfile,Xaxis);
figure(2);
plot(Xaxis,Data3.meas.RangeProfile,'Color','blue','LineStyle','-','LineWidth',2);
xlabel('Range (m)');
ylabel('Power (dB)');
hold on;
plot(Xaxis,Data4.meas.RangeProfile,'Color','red','LineStyle','--','LineWidth',2);
title('Two Angles Compare on Dual-Frequency');
legend('AWR1642(High Frequency)','IWR6843(Low Frequency)');
hold off;
