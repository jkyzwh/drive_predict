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

# 将数据框整理为喜闻乐见的形式
alignment_fix['K_End'] = alignment_fix['K_Start'] + alignment_fix['Length']
alignment_fix = alignment_fix [ ['NO','K_Start', 'K_End','Length','Road_Type','Radius','Direction',
'DirStart', 'DirEnd', 'Chord', 'delta_theta', 'constant', 'Start_X',
'Start_Y', 'End_X', 'End_Y', 'Center_X', 'Center_Y' ] ]

#----------------------------------------------------------------------
'''
生成逐桩坐标表
1. 桩号
2. x坐标
3. y坐标
-----------------------------------------------------------------------------
生成从起点至终点的整桩号矩阵，纵轴是间距为1的桩号数列，横轴是可视距离内每个点的
1.方位角（与前进方向的夹角）
2.视线距离（视线直线距离）
3.与当前位置的高差

构造一个空数据框，行数量为驾驶人数量，列数量为可视距离
列名为（k_1,k_2,.......k_xxx）
'''
# 初始化列名列表
colnames = ['k_location']
for i in range(1,view_distance+1):
    temp = 'k_'+str(i)
    colnames.append(temp)
#计算行数
row_num = alignment_fix['K_End'].iloc[len(alignment_fix.index)-1] \
- alignment_fix['K_Start'].iloc[0]
#' \'是续行符
row_num = math.floor(row_num)
# 初始化空白数据框
road_coordinate = pd.DataFrame(index=np.arange(0,row_num),columns=['k_location','x','y','hight'])
road_view =  pd.DataFrame(index=np.arange(0,row_num),columns=colnames)

del(row_num,colnames)

#==============================================================================
'''
0. 将桩号序列移植到road_view
1. 判断当前桩号所在的曲线单元类型
2. 判断可视距离内的线元的数量
3. 根据公式计算方位角和视线距离
'''

#-----------------------------------------------------------------------------
'''
首先，计算全线逐桩坐标表，
然后用最简单的方式计算方位角和距离
定义计算逐桩坐标的函数，分别对应直线、圆曲线和缓和曲线
'''
#直线上每一点的坐标计算
def coordinate_line(l,L,x1,y1,x2,y2):
    bili = l/L
    x = bili*(x2-x1)+x1
    y = bili*(y2-y1)+y1
    coordinate = [x,y]
    return(coordinate)
#圆曲线上每一点的坐标计算
'''
计算点距离曲线起点的距离
起点坐标，终点坐标
半径、曲线长、割线长
'''    
def coordinate_curve(l,x1,y1,x2,y2,R,Lr,chord):
    import math
    #割线与x轴夹角
    angle_X = math.atan((y2-y1)/(x2-x1))
    #利用余弦定理求出起点与计算点连线和平曲线割线的夹角
    b = 2*R*math.sin(l/2/R ) #三角形b边长
    a = 2*R*math.sin((Lr-l)/2/R) #三角形a边长
    c = chord
    # 余弦定理计算夹角
    cosB = (b*b+c*c-a*a)/(2*b*c)
    if cosB >=1:
        cosB = 1
    angle_C = math.acos(cosB)
    #得到计算点与起点连线和x轴的夹角为：
    
    angle = angle_C+angle_X
    #计算坐标   
    y=b*math.sin(angle)+y1
    x=b*math.cos(angle)+x1
    coordinate = [x,y]
    return(coordinate)    

def coordinate_curve2(l,x1,y1,x2,y2,R,Direction,dir1):
    import math
    #割线与x轴夹角
    
    a = 2*R*math.sin(l/2/R )
    if Direction == 'L':
        b = math.cos(dir1-(l/2/R))
        c = math.sin(dir1-(l/2/R))
    elif  Direction == 'R':
        b = math.cos(dir1+(l/2/R))
        c = math.sin(dir1+(l/2/R))
    else:
        print('Direction error')
   
    #计算坐标   
    y=a*c+y1
    x=a*b+x1
    coordinate = [x,y]
    return(coordinate)    

def coordinate_curve3(l,x1,y1,x2,y2,R,Direction,delta_theta):
    import math
    
    if Direction == 'L':
        a = -math.cos(delta_theta) * l 
        b = -math.sin(delta_theta) * l       
    elif  Direction == 'R':
        a = math.cos(delta_theta) * l
        b = math.sin(delta_theta) * l
    else:
        print('Direction error')
   
    #计算坐标   
    y=b+y1
    x=a+x1
    coordinate = [x,y]
    return(coordinate) 

#缓和曲线上每一点的坐标

def coordinate_spiral(l,x1,y1,x2,y2,R,Ls,dir1):
    import math
    #弧长对应的缓和曲线中心角度
    angle_B = l*l/2/R/Ls
    angle = angle_B + dir1    
    S = l-(l*l*l*l*l/(math.pi*R*R*Ls*Ls/2))
    #计算坐标   
    y=S*math.sin(angle)+y1
    x=S*math.cos(angle)+x1
    coordinate = [x,y]
    return(coordinate)   

#=============================================================================
'''
逐行计算逐桩坐标
'''
temp_coordinate = pd.DataFrame(columns=['k_location','x','y'])

for i in range(len(alignment_fix.index)):
    aa = alignment_fix.iloc[i]
    x1 = aa['Start_X']
    y1 = aa['Start_Y']
    x2 = aa['End_X']
    y2 = aa['End_Y']     
    a = math.floor(aa['K_Start'])
    b = math.floor(aa['K_End'])
    
    if aa['Road_Type'] == 'Line':
        L = aa['Length']   
        for i in range(a+1,b+1):
            l = i-math.floor(aa['K_Start'])
            c =  coordinate_line(l,L,x1,y1,x2,y2)
            d = pd.DataFrame([[i,c[0],c[1]]],columns=['k_location','x','y'])
            temp_coordinate = pd.concat([temp_coordinate,d],ignore_index=True)
            print(i,c)
            
    elif aa['Road_Type'] == 'Curve':
        Lr = aa['Length']
        R = aa['Radius']
        chord = aa['Chord'] 
        dir1 = aa['DirStart']
        Direction = aa['Direction']
        delta_theta = aa['delta_theta']
        
        for i in range(a+1,b+1):
            l = i-math.floor(aa['K_Start'])
            #c =  coordinate_curve(l,x1,y1,x2,y2,R,Lr,chord)
            c= coordinate_curve2(l,x1,y1,x2,y2,R,Direction,dir1)
            #c= coordinate_curve3(l,x1,y1,x2,y2,R,Direction,delta_theta)
            d = pd.DataFrame([[i,c[0],c[1]]],columns=['k_location','x','y'])
            temp_coordinate = pd.concat([temp_coordinate,d],ignore_index=True)
            print(i,c)
    
    elif aa['Road_Type'] == 'Spiral':
        Ls = aa['Length']        
        dir1 = aa['DirStart']
        if alignment_fix.iloc[i+1]['Road_Type'] == 'Curve':
            bb = alignment_fix.iloc[i+1]
        elif alignment_fix.iloc[i+1]['Road_Type'] == 'Line':
            bb = alignment_fix.iloc[i-1]
        else:
            pass
        R = bb['Radius']
        for i in range(a+1,b+1):
            l = i-math.floor(aa['K_Start'])
            c = coordinate_spiral(l,x1,y1,x2,y2,R,Ls,dir1)
            d = pd.DataFrame([[i,c[0],c[1]]],columns=['k_location','x','y'])
            temp_coordinate = pd.concat([temp_coordinate,d],ignore_index=True)
            print(i,c)   
    else:
        pass
    
            
    
#=============================================================================

'''
测试直线
'''
aa = alignment_fix.loc[0]
x1 = aa['Start_X']
y1 = aa['Start_Y']
x2 = aa['End_X']
y2 = aa['End_Y']
L = aa['Length']
a = math.floor(aa['K_Start'])
b = math.floor(aa['K_End'])

for i in range(a,b+1):
    l = i-a
    c =  coordinate_line(l,L,x1,y1,x2,y2)
    print(i,c)


'''
测试圆曲线
'''
aa = alignment_fix.loc[9]
x1 = aa['Start_X']
y1 = aa['Start_Y']
x2 = aa['End_X']
y2 = aa['End_Y']
Lr = aa['Length']
R = aa['Radius']
chord = aa['Chord']
a = math.floor(aa['K_Start'])
b = math.floor(aa['K_End'])

for i in range(a+1,b+1):
    l = i-a
    c = coordinate_curve(l,x1,y1,x2,y2,R,Lr,chord)
    print(i,c)

'''
测试缓和曲线
'''
aa = alignment_fix.loc[15]
bb = alignment_fix.loc[16]

x1 = aa['Start_X']
y1 = aa['Start_Y']
x2 = aa['End_X']
y2 = aa['End_Y']
Ls = aa['Length']
R = bb['Radius']

dir1 = aa['DirStart']

a = math.floor(aa['K_Start'])
b = math.floor(aa['K_End'])

for i in range(a+1,b+1):
    l = i-a
    c = coordinate_spiral(l,x1,y1,x2,y2,R,Ls,dir1)
    print(i,c)


#
#aa['K_Start']
#if aa['Road_Type'] == 'Line':
    
'''
利用matplotlib可视化，检查逐桩坐标计算是否正确
'''

import matplotlib.pyplot as plt
plt.plot(temp_coordinate['x'],temp_coordinate['y'])
plt.show()


    
    
    
    
