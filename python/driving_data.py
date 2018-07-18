# -*- coding: utf-8 -*-
"""
Created on Tue Jul 17 2018
本程序用于将驾驶模拟器试验数据整理为以桩号为坐标的数据集，以支持完成机器学习计算
本程序执行的前提条件是首先运行alignment_calculation脚本，将landxml文件转化为驾驶人看到的视角、距离和高差
基本要点：
1. 输入数据为特定scenario试验得到的不同驾驶人试验的原始数据
2. 分上下行，将试验数据按照桩号排序，将驾驶人ID作为分组变量
3. 选取速度、加速度、方向盘转角、油门踏板进深和刹车踏板进深作为测试指标
4. 试验最高限速值和winroad的版本号作为全局变量输入

暂时将上行方向用于模型训练，下行方向作为测试集分析模型效度

@author: Zhwh-notbook
"""
# ==============================================================================
'''
判断工作目录，操作系统，导入当前目录下的simData.py,改脚本中包含了很多常用呃函数
'''
# ===============================================================================
import sys
import platform

operat_system = platform.system()

if operat_system == 'Windows':
    scrip_dir = sys.path[11] + '/python'  # d当前脚本所在的project路径
elif operat_system == 'Linux':
    scrip_dir = sys.path[7] + '/python'  # d当前脚本所在的project路径

sys.path.append(scrip_dir)  # 将当前目录加入搜索路径

import simData as sim
import simConst as const

# ------------------------------------------------------------------------------

'''
导入几何线形视野数据
'''
import pandas as pd

if operat_system == 'Windows':
    road_view_up = pd.read_csv('D:\\PROdata\\Data\\landxml\\road_view_up.csv', header=0, encoding='utf-8')
    road_view_down = pd.read_csv('D:\\PROdata\\Data\\landxml\\road_view_down.csv', header=0, encoding='utf-8')
elif operat_system == 'Linux':
    road_view_up = pd.read_csv('/home/zhwh/My_cloud/data/landxml/road_view_up.csv', header=0, encoding='utf-8')
    road_view_down = pd.read_csv('/home/zhwh/My_cloud/data/landxml/road_view_down.csv', header=0, encoding='utf-8')
else:
    pass
# ==================================================================================
'''
导入驾驶模拟器试验数据
'''
ver = 4.0  # 使用的数据来自于winroad的版本号
colnames = const.simdata_colname(ver)


def getfilename(path):  # 定义读取指定path的全部csv文件
    file_list = os.listdir(path)
    csv_name_list = []    # 将csv文件名存入指定列表
    for i in file_list:
        # os.path.splitext():分离文件名与扩展名
        if os.path.splitext(i)[1] == '.csv':
            csv_name_list.append(i)
    return (csv_name_list)


"""
# 定义函数，将目录下所有csv文件读入工作环境，并全部存入一个列表进行存储
"""


def getsimdata(path):
    simulator_data = []
    for i in path:   # 读入csv数据
        locals()['ID_'+os.path.splitext(i)[0]]=pd.read_csv(i, header=0, names=data_name)
        simulator_data.append(locals()['ID_'+os.path.splitext(i)[0]])
    return(simulator_data)


"""
# 定义函数，将目录下所有csv文件读入工作环境，并合并至一个列表进行存储
驾驶人编号增加变量ID予以表示
"""


def getsimudata_inone(sim_dataName):
    simulator_data=pd.DataFrame()
    for i in sim_dataName:    # 读入csv数据
        A = pd.read_csv(i, header=0, names=data_name)
        A['ID']=os.path.splitext(i)[0]
        simulator_data=pd.concat([simulator_data, A])  # 将所有数据合并
    return(simulator_data)

