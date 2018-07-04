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
#==============================================================================
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
#----------------------------------------------------------------------
'''
生成从起点至终点的整桩号矩阵，纵轴是间距为1的桩号数列，横轴包括：
1.极坐标转角
2.看看后面还需要什么
'''

'''
构造一个空数据框，共13列，行数量为驾驶人数量，列名为MDS_colnames

'''
colnames = ["K_location","direction"]
#计算行数
row_num = alignment_import['K_Start'].iloc[len(alignment_import.index)-1] \
- alignment_import['K_Start'].iloc[0]
#' \'是续行符
row_num = math.floor(row_num)
# 初始化空白数据框
K_dir =  pd.DataFrame(index=np.arange(0,row_num),columns=colnames)






