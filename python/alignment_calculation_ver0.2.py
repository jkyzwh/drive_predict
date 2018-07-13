# -*- coding: utf-8 -*-
"""
Created on Tue Jul 04 2018
本程序用于将landxml导出的几何设计数据转化为支持机器学习的数据
基本要点：
1. 输入数据为从landxml中导出的平曲线表和竖曲线表
2. 分为正反两个方向，按行驶方向排列里程桩，根据设计速度对应的规则，确定驾驶人的可视距离
   将驾驶人看到的指定长度可视范围内道路的几何线形转化为视角、距离和高差
@author: Zhwh-notbook
"""
# ==============================================================================
'''
判断工作目录，操作系统，指定输入文件位置
'''

import sys
scrip_dir = sys.path[3] #d当前脚本所在路径
#--------------------------------------------------
import platform
operat_system = platform.system()
if operat_system == 'Windows':
    alignment_datapath = 'D:\\PROdata\\Data\\landxml\\SZhighway_Alignment.csv'
    para_datapath = 'D:\\PROdata\\Data\\landxml\\SZhighway_ParaCurve.csv'
else:
    alignment_datapath ='/home/zhwh/My_cloud/data/landxml/SZhighway_Alignment.csv'
    para_datapath = '/home/zhwh/My_cloud/data/landxml/SZhighway_ParaCurve.csv'
    
#=============================================================================
'''
输入设计速度作为全局变量
'''
design_speed = 100 #根据需要修改
#=============================================================================
'''
定义不同设计速度对应的可视距离
'''
if design_speed <= 30:
    view_distance = 70
elif design_speed == 40:
    view_distance = 90
elif design_speed == 50:
    view_distance = 110
elif design_speed == 60:
    view_distance = 135
elif design_speed == 70:
    view_distance = 155
elif design_speed == 80:
    view_distance = 180
elif design_speed == 90:
    view_distance = 200
elif design_speed == 100:
    view_distance = 225
elif design_speed == 110:
    view_distance = 255    
elif design_speed == 120:
    view_distance = 270
else:
    print('design speed is not correct')        
    
#==============================================================================
# 导入平曲线数据和竖曲线数据
#==============================================================================
import numpy as np
import pandas as pd
import math
'''
导入来自landxml的平曲线数据表和竖曲线数据表
'''
#--------------------------------------------------------------------
alignment_import = pd.read_csv(alignment_datapath,header=0,encoding = 'utf-8')
para_import = pd.read_csv(para_datapath,header=0,encoding = 'utf-8')
#---------------------------------------------------------------------
'''
修正平曲线表，将计算误差导致的极短直线段清除掉
定义函数
'''
def alignment_check(alignment_data,L=5): #L是用于判断需要修正的长度
    A = alignment_data
    select = []
    for i in range(len(A.index)):
        if A['Length'].iloc[i] >=L :
            select.append(A.index[i])
        else:
            A['K_Start'].values[i+1] = A['K_Start'].iloc[i]
            
            A['Length'].values[i+1] = A['K_Start'].iloc[i+2]-A['K_Start'].iloc[i+1]
    B = A.loc[select]
    return(B)

alignment_fix = alignment_check(alignment_import,5)

# 将数据框整理为喜闻乐见的形式
alignment_fix['K_End'] = alignment_fix['K_Start'] + alignment_fix['Length']
alignment_fix = alignment_fix [ ['NO','K_Start', 'K_End','Length','Road_Type','Radius','Direction',
'DirStart', 'DirEnd', 'Chord', 'delta_theta', 'constant', 'Start_X',
'Start_Y', 'End_X', 'End_Y', 'Center_X', 'Center_Y' ] ]

'''
1. 根据相邻曲线表，填写直线段方位角
2. 将缓和曲线接圆曲线时，圆曲线的方位角修正为不包含缓和曲线线元
'''
for i in range(len(alignment_fix.index)):
    aa = alignment_fix.iloc[i]
    if aa['Road_Type'] == 'Spiral':
        a = alignment_fix['DirStart'].iloc[i]
        b = alignment_fix['DirEnd'].iloc[i]
        alignment_fix['DirStart'].values[i] = b
        alignment_fix['DirEnd'].values[i] = a
    else:
        pass

for i in range(len(alignment_fix.index)):
    print(i)
    if alignment_fix['Road_Type'].iloc[i] == 'Line':
        if i == 0:
            alignment_fix['DirStart'].values[i] = alignment_fix['DirStart'].iloc[i + 1]
            alignment_fix['DirEnd'].values[i] = alignment_fix['DirStart'].iloc[i + 1]
        elif i == (len(alignment_fix.index)-1):
            alignment_fix['DirStart'].values[i] = alignment_fix['DirEnd'].iloc[i - 1]
            alignment_fix['DirEnd'].values[i] = alignment_fix['DirEnd'].iloc[i - 1]
        elif i > 0 and i < (len(alignment_fix.index)-1):
            alignment_fix['DirStart'].values[i] = alignment_fix['DirEnd'].iloc[i - 1]
            alignment_fix['DirEnd'].values[i] = alignment_fix['DirStart'].iloc[i + 1]


#----------------------------------------------------------------------
'''
生成逐桩方位角表
1. 桩号
2. 方位角
将单元内方位角变化根据曲率分配至每个桩号
'''
#直线上每一点的坐标计算
def direction_line (l, Ll, dir1, dir2):
    bili = l/Ll
    x = bili*(dir2-dir1)+dir1
    return(x)

#圆曲线上每一点的坐标计算
def direction_curve(l, Lr, dir1, dir2):
    bili = l/Lr
    x = bili*(dir2-dir1)+dir1
    return(x)
# 缓和曲线上每一点的坐标计算

def direction_spiral(l, Ls, R1, R2, dir1, dir2):
    import math
    R = l/Ls*(R2-R1)+R1
    x = (R-R1)*(dir2-dir1)/(R2-R1)+dir1
    return(x)

#-----------------------------------------------------------------------------

'''
计算每个桩号的方位角
'''
temp_dir = pd.DataFrame(columns = ['k_location', 'Type', 'dir'])

for i in range(len(alignment_fix.index)):
    aa = alignment_fix.iloc[i]
    dir1 = aa['DirStart']
    dir2 = aa['DirEnd']
    a = math.floor(aa['K_Start'])
    b = math.floor(aa['K_End'])

    if aa['Road_Type'] == 'Line':
        Ll = aa['Length']
        for j in range(a + 1, b + 1):
            l = j - math.floor(aa['K_Start'])
            c = direction_line(l, Ll, dir1, dir2)
            d = pd.DataFrame([[j, 'Line', c]], columns=['k_location', 'Type', 'dir'])
            temp_dir = pd.concat([temp_dir, d], ignore_index=True)
            print(j, 'Line', c)

    elif aa['Road_Type'] == 'Curve':
        Lr = aa['Length']
        for k in range(a + 1, b + 1):
            l = k - math.floor(aa['K_Start'])
            c = direction_curve(l, Lr, dir1, dir2)
            d = pd.DataFrame([[k, 'Curve', c]], columns=['k_location', 'Type', 'dir'])
            temp_dir = pd.concat([temp_dir, d], ignore_index=True)
            print(k, 'Curve', c)

    elif aa['Road_Type'] == 'Spiral':
        Ls = aa['Length']

        if alignment_fix['Road_Type'].iloc[i - 1] == 'Line':
            R1 = 20000
        elif alignment_fix['Road_Type'].iloc[i - 1] == 'Curve':
            R1 = alignment_fix['Radius'].iloc[i - 1]
        else:
            pass

        if alignment_fix['Road_Type'].iloc[i + 1] == 'Curve':
            R2 = alignment_fix['Radius'].iloc[i + 1]
        elif alignment_fix['Road_Type'].iloc[i + 1] == 'Line':
            R2 = 20000
        else:
            pass

        for j in range(a + 1, b + 1):
            l = j - math.floor(aa['K_Start'])
            c = direction_spiral(l, Ls, R1, R2, dir1, dir2)
            d = pd.DataFrame([[j, 'Spiral', c]], columns=['k_location', 'Type', 'dir'])
            temp_dir = pd.concat([temp_dir, d], ignore_index=True)
            print(j, 'Spiral', c)
    else:
        pass

del(aa, a, b, c, d, i, j, k, l, Ll, Lr, Ls, R1, R2, dir1, dir2)

'''
利用matplotlib可视化，检查方位角计算是否正确
'''

# ===================================================================================================
'''
计算每个桩号处的高程
1. 竖曲线表，起点，终点，类型（直线，竖曲线）,起点纵坡，终点纵坡，起点高程，终点高程
    i 是计算所得，由于忽略了竖曲线影响，已经存在误差，但是里程较长，坡度较小时可以忽略
    准确的数据为：桩号、竖曲线长度、高程
2. 每一点的高程，测试阶段将变坡点处简化为折线先行计算
'''

para_import['K_End'] = 0.0
para_import['Height_End'] = 0.0
for i in range(len(para_import.index)-1):
    para_import['K_End'].values[i] = para_import['K_Start'].iloc[i+1]
    para_import['Height_End'].values[i] = para_import['Height'].iloc[i+1]
para_import['Length'] = para_import['K_End'] - para_import['K_Start']
para_import['i'] = (para_import['Height_End'] - para_import['Height']) / para_import['Length']

para_import = para_import[['NO', 'K_Start', 'K_End', 'Length', 'Height',
                           'Height_End', 'i', 'VCL']]

temp_height = pd.DataFrame(columns=['k_location', 'height'])


for i in range(len(para_import.index)-1):
    aa = para_import.iloc[i]
    h1 = aa['Height']
    h2 = aa['Height_End']
    L = aa['Length']
    a = math.floor(aa['K_Start'])
    b = math.floor(aa['K_End'])

    for j in range(a + 1, b + 1):
        l = j - math.floor(aa['K_Start'])
        c = l/L*(h2-h1)+h1
        d = pd.DataFrame([[j, c]], columns=['k_location', 'height'])
        temp_height = pd.concat([temp_height, d], ignore_index=True)
        print(j, c)
del(aa, a, b, c, d, i, j, l, L, h1, h2)

road_info = pd.merge(temp_dir, temp_height, on='k_location')
del(temp_height, temp_dir)

# 绘制方位角和纵断面图
plt.figure(num=1)
plt.plot(road_info['k_location'], road_info['height'])

plt.figure(num=2)
plt.plot(road_info['k_location'], road_info['dir'], color='red')
plt.show()


'''
生成从起点至终点的整桩号矩阵，纵轴是间距为1的桩号数列，横轴是可视距离内每个点的
1.方位角（与前进方向的夹角）
2.视线距离（视线直线距离）
3.与当前位置的高差

构造一个空数据框，行数量为驾驶人数量，列数量为可视距离
列名为（k_1,k_2,.......k_xxx）
'''
# 初始化列名列表
colnames = ['k_location']
for i in range(1, view_distance+1):
    temp = 'k_'+str(i)
    colnames.append(temp)
# 计算行数
row_num = len(road_info.index)-view_distance

# 初始化空白数据框
road_view = pd.DataFrame(index=np.arange(0, row_num), columns=colnames)

'''
计算驾驶人行驶过程中几何线形的视觉矩阵
'''

for i in range(len(road_view.index)):
    road_view['k_location'].values[i] = road_info['k_location'].iloc[i]


for i in range(len(road_view.index)):
    temp_row = [road_info['k_location'].iloc[i]]
    for j in range(1, view_distance+1):
        a = road_info['dir'].iloc[i+j] - road_info['dir'].iloc[i]
        b = road_info['k_location'].iloc[i+j] - road_info['k_location'].iloc[i]
        c = road_info['height'].iloc[i+j] - road_info['height'].iloc[i]
        temp = [a,b,c]
        temp_row.append(temp)
        print(j)



del(row_num, colnames)

# ==============================================================================
'''
0. 将桩号序列移植到road_view
1. 判断当前桩号所在的曲线单元类型
2. 判断可视距离内的线元的数量
3. 根据公式计算方位角和视线距离
'''

