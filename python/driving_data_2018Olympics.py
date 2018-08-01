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

operation_system = platform.system()

if operation_system == 'Windows':
    scrip_dir = sys.path[10] + '/python'  # d当前脚本所在的project路径
elif operation_system == 'Linux':
    scrip_dir = sys.path[8] + '/python'  # d当前脚本所在的project路径

sys.path.append(scrip_dir)  # 将当前目录加入搜索路径++

UC_VER = 13   # 使用的数据来自于winroad的版本号
if UC_VER >=10:
    SPEED_LIMIT = 80  # 限速设置
elif UC_VER == 4:
    SPEED_LIMIT = 40/3.6  # 限速设置
else:
    pass

# import simData as sim
import simConst as const

# ------------------------------------------------------------------------------

'''
导入几何线形视野数据
'''
import pandas as pd

print('导入几何线形在驾驶人视野中的矩阵描述文件')
if operation_system == 'Windows':
    road_view_up = pd.read_csv('D:\\PROdata\\Data\\2018Olympics\\Road_Data\\road_view_up.csv', header=0, encoding='utf-8')
    road_view_down = pd.read_csv('D:\\PROdata\\Data\\2018Olympics\\Road_Data\\road_view_down.csv', header=0, encoding='utf-8')
elif operation_system == 'Linux':
    road_view_up = pd.read_csv('/home/zhwh/Data/2018Olympics/Driver_Data/road_view_up.csv', header=0, encoding='utf-8')
    road_view_down = pd.read_csv('/home/zhwh/Data/2018Olympics/Driver_Data/road_view_down.csv', header=0, encoding='utf-8')
else:
    pass

# ==================================================================================
'''
导入驾驶模拟器试验数据
首先读取数据目录下所有的csv文件
'''
import os

if operation_system == 'Windows':
    simdata_path = 'D:\\PROdata\\Data\\2018Olympics\\Driver_Data\\up'
elif operation_system == 'Linux':
    simdata_path = '/home/zhwh/Data/2018Olympics/Driver_Data/up'
else:
    pass


colnames = const.simdata_colname(UC_VER)

"""
#定义函数，将模拟器数据按空间序列排序，间距为传入函数的数值
"""


def orderDataDis(data, ver, step=1):
    if ver == 4:
        data['Dis'] = pd.to_numeric(data['Dis']) // step * step
        data_order = data.drop_duplicates(['Dis'])  # 丢弃重复的行数据
    elif ver == 10:
        data['disFromRoadStart'] = pd.to_numeric(data['disFromRoadStart']) // step * step
        data_order = data.drop_duplicates(['disFromRoadStart'])  # 丢弃重复的行数据
    elif ver >= 12:
        data['disFromRoadStart'] = pd.to_numeric(data['disFromRoadStart']) // step * step
        data_order = data.drop_duplicates(['disFromRoadStart'])  # 丢弃重复的行数据
    else:
        print('Uc-winroad版本号错误')
    return data_order


def getsimdata(data_path):  # 读取指定目录下的csv文件，存储在一个列表中
    file_list = os.listdir(data_path)
    sim_data = []
    for i in file_list:
        # os.path.splitext():分离文件名与扩展名
        if os.path.splitext(i)[1] == '.csv':
            if operation_system == 'Windows':
                csv_path = data_path + '\\' + str(i)
            elif operation_system == 'Linux':
                csv_path = data_path + '/' + str(i)
            else:
                pass
            print('import', csv_path)
            temp = pd.read_csv(csv_path, header=0, low_memory=False)
            temp.columns = colnames
            sim_data.append(temp)
        else:
            pass

    return sim_data


simData_list = getsimdata(simdata_path)


'''
将所有人数据汇总到一个数据框，增加驾驶人ID数据
增加前一个桩号处的速度
'''
colnames.append('driver_ID')
# sim_data = pd.DataFrame(columns=colnames)
sim_data = pd.DataFrame()
for i in range(len(simData_list)):
    A = simData_list[i]
    A['driver_ID'] = ('ID_' + str(i))
    B = orderDataDis(A, UC_VER, step=1)
    print('正在合并第', (i + 1), '个数据')
    if UC_VER == 4:
        temp_index = list(B.index)
        temp = B.drop([temp_index[0]], axis=0)
        B = B.drop([temp_index[len(temp_index)-1]], axis=0)
        temp['speed_lastlocation'] = list(B['Speed'])
    elif UC_VER >= 10:
        temp_index = list(B.index)
        temp = B.drop([temp_index[0]], axis=0)
        B = B.drop([temp_index[len(temp_index) - 1]], axis=0)
        temp['speed_lastlocation'] = list(B['speedKMH'])
    else:
        print('版本号错误')
    sim_data = pd.concat([sim_data, temp], ignore_index=True, sort=False)  # 将所有数据合并

sim_data['speed_limit'] = SPEED_LIMIT  #增加限速列
del (A, B, temp, temp_index)

# ==================================================================================
'''
下面要做的是将驾驶人视野内数据与需要的试验数据匹配
'''
ID_list = sim_data.drop_duplicates(['driver_ID'])['driver_ID']  # 获取所有的驾驶人ID
training_data = pd.DataFrame()
for i in range(len(ID_list)):
    locals()['ID_' + str(i)] = sim_data[sim_data['driver_ID'] == ('ID_' + str(i))]
    if UC_VER == 4:
        locals()['ID_' + str(i)] = locals()['ID_' + str(i)][
            ['driver_ID', "Dis", "Speed", 'speed_lastlocation', 'speed_limit', "Acc_surge", "Acc_sway", 'Steering',
             'Acc_pedal', 'Brake_pedal']]
        locals()['testdata_' + str(i)] = pd.merge(locals()['ID_' + str(i)], road_view_up, how='inner',
                                                  right_on='k_location'
                                                  , left_on='Dis')
        print('将第', i, '个驾驶员数据添加进训练集')
        training_data = pd.concat([training_data, locals()['testdata_' + str(i)]], ignore_index=True,
                                  sort=False)  # 将所有数据合并
    if UC_VER >= 10:
        locals()['ID_' + str(i)] = locals()['ID_' + str(i)][
            ['driver_ID', "disFromRoadStart", "speedKMH", 'speed_lastlocation', 'speed_limit']]
        locals()['testdata_' + str(i)] = pd.merge(locals()['ID_' + str(i)], road_view_up, how='inner',
                                                  right_on='k_location'
                                                  , left_on='disFromRoadStart')
        print('将第', i, '个驾驶员数据添加进训练集')
        training_data = pd.concat([training_data, locals()['testdata_' + str(i)]], ignore_index=True,
                                  sort=False)  # 将所有数据合并
    else:
        print('版本号错误')
'''
将训练数据集存储在硬盘上
'''
'''
需要时将存储在硬盘上的文件读入内存
'''

if operation_system == 'Windows':
    training_data.to_csv('D:\\PROdata\\Data\\2018Olympics\\Driver_Data\\training_data.csv', index=False, sep=',')
elif operation_system == 'Linux':
    training_data.to_csv('/home/zhwh/Data/2018Olympics/Driver_Data/training_data.csv', index=False, sep=',')
else:
    pass

'''
使用上行数据进行训练，下行数据用于测试
'''
