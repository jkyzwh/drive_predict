# -*- coding: utf-8 -*-
"""
驾驶模拟器数据分析常用函数和变量
作者：张巍汉
1. data_name：模拟器数据重新命名列名
2. getFileName：获取工作目录下所有csv文件的名称
3. getSimulatorData：将所有csv文件导入，并存入一个列表返回
"""
#from pandas import  Series, DataFrame
import pandas as pd
import os

"""
定义函数计算横向加速度/角速度的函数,用于map()调用
"""
def DiffRow(x,y):# 计算横向加速度/角速度的函数
    if y==0:
       y=0
    else:
       y=abs(x/y)
    return(float(y))

"""
#定义函数，将模拟器数据按空间序列排序，间距为传入函数的数值
"""
def orderDataDis(data,step=1):
    data.Dis=data.Dis//step*step
    dataOrder=data.drop_duplicates(['Dis']) #丢弃重复的行数据
    return(dataOrder)
 

"""
#定义函数，将模拟器数据按时间序列排序，间距为传入函数的数值
"""
def orderDataTime(data,step=1):
    data.Time=data.Time//step*step
    dataOrder=data.drop_duplicates(['Time'])
    return(dataOrder)   
    
"""
定义函数，计算数据行之间的差值，需要注意的是，传入数据不能包括字符型等不能减法的数据类型
"""
def rowMinus(data):
    minus=data.diff(1,axis="index")
    minus=minus.drop(0,axis="index")
    minus=abs(minus)
    return(minus)
    
"""
定义函数筛选出*.csv文件，将文件名存入新的变量csv_file_name
"""
def getFileName(path):
    ''' 获取指定目录下的所有指定后缀的文件名 '''
    file_list = os.listdir(path)
    csv_name_list=[]
    # 将csv文件名存入指定列表
    for i in file_list:
        # os.path.splitext():分离文件名与扩展名
        if os.path.splitext(i)[1] == '.csv':
            csv_name_list.append(i)
    return(csv_name_list)

"""
# 定义函数，将目录下所有csv文件读入工作环境，并全部存入一个列表进行存储
"""
def getSimulatorData(path):
    simulator_data=[]
    for i in path:
        #读入csv数据
        locals()['ID_'+os.path.splitext(i)[0]]=pd.read_csv(i,header=0,names=data_name) 
        simulator_data.append(locals()['ID_'+os.path.splitext(i)[0]])
    return(simulator_data)

"""
# 定义函数，将目录下所有csv文件读入工作环境，并合并至一个列表进行存储
驾驶人编号增加变量ID予以表示
"""
def getSimulatorDataInOne(sim_dataName):
    simulator_data=pd.DataFrame()
    for i in sim_dataName:
        #读入csv数据
        A=pd.read_csv(i,header=0,names=data_name)
        A['ID']=os.path.splitext(i)[0]
        simulator_data=pd.concat([simulator_data,A])#将所有数据合并
    return(simulator_data)


"""
定义异常驾驶行为原始数据框，多个驾驶人数据汇总为一个总表，用ID变量进行区分
增加方向盘转角速率、刹车踏板速率、横向偏向变化率和横向加速度/角速度变量

函数输入项为包含实验数据名称的列表
"""
def getSimulatorDataAbnormalInOne(sim_data_name,step):
    simulator_data=pd.DataFrame()
    for i in sim_data_name:
        #读入csv数据
        A=pd.read_csv(i,header=0,names=data_name)
        A['ID']=os.path.splitext(i)[0] #增加驾驶人ID数据项
        A['Speed']=A['Speed']*3.6 #将速度转化为km/h
        # 增加方向盘转角差值/时间差值的方向盘转动速率
        A['Steering_diff']=abs(A.Steering.diff()/A.Time.diff())
        #增加横向偏移相对于前进距离的变化速率 
        A['offsset_diff']=list(map(DiffRow,A.Lane_offset,A.Dis))
        #增加刹车踏板进深的变化速率 
        A['brake_diff']=A.Brake_pedal.diff()/A.Time.diff()
        #增加横向加速度/角速度
        A['Ax_Yspeed']=list(map(DiffRow,A.Acc_sway,A.Yaw_speed))
        #增加按速度分组的列，分组间隔为输入数据step
        A['speed_split']=abs(A.Speed)//step+1
        
        simulator_data=pd.concat([simulator_data,A])#将所有数据合并
    return(simulator_data)
    










  
  
  
