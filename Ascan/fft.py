import numpy as np
import matplotlib
matplotlib.use('TkAgg')  # 指定使用TkAgg后端
import matplotlib.pyplot as plt
from scipy.fft import fft, fftshift

# 设置 Matplotlib 的中文字体
matplotlib.rcParams['font.sans-serif'] = ['SimHei']  # 设置中文字体为黑体
matplotlib.rcParams['axes.unicode_minus'] = False  # 正确显示负号

# 读取文件
filename = '900and1800.txt'
signal = np.loadtxt(filename)

# 绘制原始信号图像
plt.figure()
plt.plot(signal)
plt.title('原始信号图像')
plt.xlabel('样本点')
plt.ylabel('信号幅度')
plt.show()

# 采样参数
dt = 4.717308673499368e-12  # 时间步长
fs = 1 / dt  # 采样频率
total_time = 5e-8  # 总时间
N = int(total_time / dt)  # 采样点数

# 补零到最接近的2的幂次
N_padded = 2 ** (int(np.ceil(np.log2(N))))
signal_padded = np.pad(signal, (0, N_padded - len(signal)), mode='constant')

# 对信号进行傅里叶变换
frequencies = np.linspace(-fs/2, fs/2, N_padded)  # 频率轴
signal_fft = fft(signal_padded)
signal_fft_shift = fftshift(signal_fft)

# 绘制频谱图
plt.figure()
plt.plot(frequencies, np.abs(signal_fft_shift))
plt.title('信号频谱图')
plt.xlabel('频率 (Hz)')
plt.ylabel('幅度')
plt.show()

# 分离900MHz和1800MHz信号
# 设计带通滤波器参数
f1 = 900e6  # 900MHz信号中心频率
f2 = 1800e6  # 1800MHz信号中心频率
bw = 100e6  # 带宽，可根据实际情况调整

# 将实际频率转换为归一化频率
fn1_low = (f1 - bw/2) / (fs/2)
fn1_high = (f1 + bw/2) / (fs/2)
fn2_low = (f2 - bw/2) / (fs/2)
fn2_high = (f2 + bw/2) / (fs/2)

# 检查归一化频率是否在允许范围内
if not (0 < fn1_low < 1 and 0 < fn1_high < 1 and 0 < fn2_low < 1 and 0 < fn2_high < 1):
    raise ValueError("归一化频率不在允许范围内 (0 < Wn < 1)。请检查频率参数。")

# 使用FFT结果分离信号
# 创建频率掩膜
mask_900 = np.abs(frequencies) >= fn1_low * fs/2
mask_900 &= np.abs(frequencies) <= fn1_high * fs/2

mask_1800 = np.abs(frequencies) >= fn2_low * fs/2
mask_1800 &= np.abs(frequencies) <= fn2_high * fs/2

# 应用掩膜
signal_900_fft = signal_fft_shift * mask_900
signal_1800_fft = signal_fft_shift * mask_1800

# 反傅里叶变换
signal_900 = np.real(np.fft.ifft(fftshift(signal_900_fft)))
signal_1800 = np.real(np.fft.ifft(fftshift(signal_1800_fft)))

# 绘制分离后的信号图像
plt.figure()
plt.subplot(2, 1, 1)
plt.plot(signal_900)
plt.title('900MHz信号')
plt.xlabel('样本点')
plt.ylabel('信号幅度')

plt.subplot(2, 1, 2)
plt.plot(signal_1800)
plt.title('1800MHz信号')
plt.xlabel('样本点')
plt.ylabel('信号幅度')
plt.show()

# 绘制分离信号的频谱图
# 对分离后的信号进行傅里叶变换
signal_900_fft = fft(signal_900)
signal_1800_fft = fft(signal_1800)

# 频率轴
frequencies = np.linspace(-fs/2, fs/2, len(signal_900_fft))

# 绘制900MHz信号的频谱图
plt.figure()
plt.plot(frequencies, np.abs(fftshift(signal_900_fft)))
plt.title('900MHz信号频谱图')
plt.xlabel('频率 (Hz)')
plt.ylabel('幅度')
plt.grid()
plt.show()

# 绘制1800MHz信号的频谱图
plt.figure()
plt.plot(frequencies, np.abs(fftshift(signal_1800_fft)))
plt.title('1800MHz信号频谱图')
plt.xlabel('频率 (Hz)')
plt.ylabel('幅度')
plt.grid()
plt.show()

# 保存分离后的信号到txt文件
np.savetxt('900.txt', signal_900)
np.savetxt('1800.txt', signal_1800)

print('分离后的信号已保存到900.txt和1800.txt')