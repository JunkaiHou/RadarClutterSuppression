import numpy as np
import matplotlib
matplotlib.use('TkAgg')  # 指定使用TkAgg后端
import matplotlib.pyplot as plt

def find_local_maxima(data, threshold=2.5, max_value=10):
    """找到数据中的局部最大值，忽略接近零或大于100的值"""
    maxima = []
    for i in range(1, len(data) - 1):
        if data[i] > threshold and data[i] < max_value and data[i] > data[i-1] and data[i] > data[i+1]:
            maxima.append(i)
    # 检查列表的第一个和最后一个元素是否也是局部最大值
    if len(data) > 1 and data[0] > threshold and data[0] < max_value and data[0] > data[1]:
        maxima.insert(0, 0)
    if len(data) > 1 and data[-1] > threshold and data[-1] < max_value and data[-1] > data[-2]:
        maxima.append(len(data) - 1)
    return maxima

def calculate_instantaneous_power(voltage):
    """计算瞬时功率"""
    return voltage ** 2

# 读取数据
data1 = np.loadtxt('900.txt')
data2 = np.loadtxt('1800.txt')

# 找到局部最大值
maxima_indices1 = find_local_maxima(data1)
maxima_indices2 = find_local_maxima(data2)

# 计算瞬时功率
power1 = calculate_instantaneous_power(data1)[maxima_indices1]
power2 = calculate_instantaneous_power(data2)[maxima_indices2]

# 打印结果
print("Local maxima indices and powers for signal 1:")
for idx, p in zip(maxima_indices1, power1):
    print(f"Index: {idx}, Power: {p}")

print("\nLocal maxima indices and powers for signal 2:")
for idx, p in zip(maxima_indices2, power2):
    print(f"Index: {idx}, Power: {p}")

# 打印局部最大值的数量
print(f"\nNumber of local maxima for signal 1: {len(power1)}")
print(f"Number of local maxima for signal 2: {len(power2)}")

# 计算并打印功率比值
if len(power1) > 0 and len(power2) > 0:
    min_length = min(len(power1), len(power2))
    power_ratios = np.array(power2[:min_length]) / np.array(power1[:min_length])
    print("\nPower ratios of signal 2 to signal 1:")
    for ratio in power_ratios:
        print(f"Ratio: {ratio}")
    print(f"Average ratio: {np.mean(power_ratios)}")
else:
    print("\nNot enough local maxima to calculate power ratios.")

# 可视化结果
plt.figure(figsize=(12, 6))
plt.plot(data1, label='Signal 1', color='blue')
plt.plot(data2, label='Signal 2', color='red')
# plt.scatter(maxima_indices1, data1[maxima_indices1], color='blue', zorder=5, label='Local maxima 1')
# plt.scatter(maxima_indices2, data2[maxima_indices2], color='red', zorder=5, label='Local maxima 2')
plt.xlabel('Time [s]')
plt.ylabel('Ez field strength [V/m]')
plt.title('Comparison of Signals and Local Maxima')
plt.legend()
plt.grid(True)
plt.show()