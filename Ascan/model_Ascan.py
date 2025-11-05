"""
python运行gprmax
读取.in文件
运行api函数模拟
"""

import os
import numpy as np
from gprMax.gprMax import api
from tools.outputfiles_merge import get_output_data, merge_files
import matplotlib
matplotlib.use('TkAgg')  # 或者尝试 'Agg', 'Qt5Agg', 'GTK3Agg' 等
import matplotlib.pyplot as plt

# 文件路径+文件名
dmax = r"./gprmaxCode"  # 项目目录
filename = os.path.join(dmax, 'sst.in')
# 正演  n：仿真次数（A扫描次数）->B扫描
api(filename, n=1, geometry_only=False ,gpu=None)  # geometry_only：仅几何图形
# merge_files(r".\GprmaxCode\concrete_Ascan_2D", removefiles=True)

# 获取回波数据
# A B扫描时out文件名不一样
filename = os.path.join(r"gprmaxCode/sst.out")
rxnumber = 1
rxcomponent = 'Ez'
outputdata, dt = get_output_data(filename, rxnumber, rxcomponent)
# print(dt)

# 保存回波数据
np.savetxt('900and1800.txt', outputdata, delimiter=' ')

# A扫描绘图
from tools.plot_Ascan import mpl_plot
from gprMax.receivers import Rx

outputs = Rx.defaultoutputs
outputs = ['Ez']
# print(outputs)
plt = mpl_plot(filename, outputs)
plt.show()