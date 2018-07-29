# -*- coding: utf-8 -*-
"""
Created on Tue Jul 17 2018
本程序用于利用驾驶模拟器试验数据整理的以桩号为坐标的数据集，
训练运行速度或其它指标的神经网络模型

暂时将上行方向用于模型训练，下行方向作为测试集分析模型效度

@author: Zhwh-notbook
"""
# ==============================================================================
import os
# import sys
import platform
operation_system = platform.system()
os.environ['KERAS_BACKEND'] = 'tensorflow'

UC_VER = 4   # 使用的数据来自于winroad的版本号
SPEED_LIMIT = 100/3.6  # 限速设置

# import tensorflow as tf
import numpy as np
import pandas as pd

print('读入存贮在硬盘上的驾驶行为数据和几何线形数据整合后的训练数据集')

if operation_system == 'Windows':
    training_data = pd.read_csv('D:\\PROdata\\Data\\landxml\\training_data.csv', header=0, encoding='utf-8')
elif operation_system == 'Linux':
    training_data = pd.read_csv('/home/zhwh/My_cloud/data/landxml/training_data.csv', header=0, encoding='utf-8')
else:
    pass
'''
将ID为零的驾驶人数据作为测试集
其余驾驶人数据作为训练集
'''
ID_list = training_data.drop_duplicates(['driver_ID'])['driver_ID']  # 获取所有的驾驶人ID
data_train = training_data[training_data['driver_ID'] != ID_list[0]].copy()
data_test = training_data[training_data['driver_ID'] == ID_list[0]].copy()

# SettingWithCopyWarning: 警告的解决方式
data_train.loc[:, 'Speed'] = data_train['Speed'].apply(lambda x: (x/SPEED_LIMIT))
data_train.loc[:, 'speed_lastlocation'] = data_train['speed_lastlocation'].apply(lambda x: (x/SPEED_LIMIT))
# data_train.loc[:, 'speed_limit'] = data_train['speed_limit'].apply(lambda x: (x/SPEED_LIMIT))

data_test.loc[:, 'Speed'] = data_test['Speed'].apply(lambda x: (x/SPEED_LIMIT))
data_test.loc[:, 'speed_lastlocation'] = data_test['speed_lastlocation'].apply(lambda x: (x/SPEED_LIMIT))
# data_test.loc[:, 'speed_limit'] = data_test['speed_limit'].apply(lambda x: (x/SPEED_LIMIT))

# # colnames = data_train.columns.values.tolist()


'''
将训练集和测试集均转化为numpy数组
'''
data_train =data_train.drop(['driver_ID', 'speed_limit', 'Dis', 'k_location', "Acc_surge", "Acc_sway", 'Steering',
             'Acc_pedal', 'Brake_pedal'], axis=1)
data_test = data_test.drop(['driver_ID', 'Dis', 'speed_limit', 'k_location', "Acc_surge", "Acc_sway", 'Steering',
             'Acc_pedal', 'Brake_pedal'], axis=1)


x_train = np.array(data_train.iloc[0:len(data_train), list(range(1, len(data_train.iloc[0])))])
y_train = np.array(data_train['Speed'])
len(x_train)-len(y_train)

x_test = np.array(data_test.iloc[0:len(data_test), list(range(1, len(data_test.iloc[0])))])
y_test = np.array(data_test['Speed'])
len(x_test)-len(y_test)

x_train = x_train.astype(np.float32)
y_train = y_train.astype(np.float32)
x_test = x_test.astype(np.float32)
y_test = y_test.astype(np.float32)


'''
构建神经网络，利用训练集进行测试
定义用于训练的神经网络
'''

import keras
from keras.models import Sequential
from keras.layers.core import Dense, Activation
from keras.optimizers import SGD, Adadelta, Adagrad, RMSprop
from keras.layers import Dropout
from keras import metrics

# from keras.utils import np_utils  #用于分类器的矢量编码

np.random.seed(1671)  # 重复性测试

N_HIDDEN = 128  # 隐藏层神经元数量
BATCH_SIZE = 120  # 每次训练的数据数量
VERBOSE = 1  # 训练过程的中间结果的输出方式
VALIDATION_SPLIT = 0.25  # 训练集用于验证的划分比例
DROPOUT = 0.3
EPOCHS = 2  # 训练的次数
SHAPE = 676

'''
构建一个全连接神经网络，用于训练
'''
DenseModel = Sequential()

# 输入层

DenseModel.add(Dense(units=N_HIDDEN, input_dim=SHAPE))
DenseModel.add(Activation('relu'))

# 隐藏层

DenseModel.add(Dense(N_HIDDEN))
DenseModel.add(Activation('relu'))
DenseModel.add(Dropout(DROPOUT))

DenseModel.add(Dense(N_HIDDEN))
DenseModel.add(Activation('relu'))
DenseModel.add(Dropout(DROPOUT))

# DenseModel.add(Dense(N_HIDDEN))
# DenseModel.add(Activation('relu'))
# DenseModel.add(Dropout(0.2))
#
# DenseModel.add(Dense(N_HIDDEN))
# DenseModel.add(Activation('relu'))
# DenseModel.add(Dropout(0.2))

# 输出层

DenseModel.add(Dense(1))
DenseModel.add(Activation('sigmoid'))

'''
在训练模型之前，您需要配置学习过程，这是通过 compile 方法完成的。它接收三个参数：
优化器 optimizer。它可以是现有优化器的字符串标识符，如 rmsprop 或 adagrad，也可以是 Optimizer 类的实例。详见：optimizers。
损失函数 loss，模型试图最小化的目标函数。它可以是现有损失函数的字符串标识符，如 categorical_crossentropy 或  mse，也可以是一个目标函数。详见：losses。
评估标准 metrics。对于任何分类问题，你都希望将其设置为 metrics = ['accuracy']。评估标准可以是现有的标准的字符串标识符，也可以是自定义的评估标准函数。
'''
# 根据训练数据和期望值，定义评估函数


def y_pred(y_true, y_pred):
    return y_pred*100


def y_true(y_true, y_pred):
    return y_true*100

# def plus_pred(y_true, y_pred):
#     return (y_pred-y_true)

def plus_pred100(y_true, y_pred):
    return (y_pred-y_true)*100


def correct_rates(y_true, y_pred):
    return (y_pred-y_true)*100/y_true

# 编译全连接神经网络DenseModel

DenseModel.compile(
    loss='mean_squared_error',
    optimizer='RMSprop',
    # metrics=['accuracy', y_pred, y_true, plus_pred100, correct_rates]
    metrics=['mean_absolute_percentage_error', y_pred, y_true, plus_pred100, correct_rates]
)

'''
训练神经网络
'''
DenseModel_train = DenseModel.fit(
    x_train, y_train,
    batch_size=BATCH_SIZE,
    epochs=EPOCHS,
    verbose=VERBOSE,
    validation_split=VALIDATION_SPLIT
)

score = DenseModel.evaluate(x_test, y_test, batch_size=BATCH_SIZE, verbose=VERBOSE)

print("test score", score[0])
print("测试的MAPE，平均绝对百分误差为", score[1])

'''
读入下行road_view数据，假设速度初始值和限速值，测试训练模型的准确程度
'''
print('导入下行方向几何线形在驾驶人视野中的矩阵描述文件')
if operation_system == 'Windows':
    road_view_down = pd.read_csv('D:\\PROdata\\Data\\landxml\\road_view_down.csv', header=0, encoding='utf-8')
elif operation_system == 'Linux':
    road_view_down = pd.read_csv('/home/zhwh/My_cloud/data/landxml/road_view_down.csv', header=0, encoding='utf-8')
else:
    pass

data_predict = road_view_down.drop(['k_location'], axis=1)
'''
将前一个桩号速度和限制速度数据列添加到模型要求的位置
首先利用insert属性，将字符串插入到列名list
然后调用 re_index 属性将数据框根据列名顺序重排
'''

BEGIN_SPEED = 10/3.6
# SHAPE = 676

colnames = data_predict.columns.tolist()
colnames.insert(0, 'speed_lastlocation')
# colnames.insert(1, 'speed_limit')

data_predict['speed_lastlocation'] = BEGIN_SPEED
# data_predict['speed_limit'] = SPEED_LIMIT

data_predict = data_predict.reindex(columns=colnames)

x_predict = np.array(data_predict)
x_predict = x_predict.astype(np.float32)

y_speed = []

for i in range(len(x_predict)):
    x_i = x_predict[i, :]
    x_i = x_i.reshape(1, SHAPE)
    y_i = DenseModel.predict(x_i, batch_size=1, verbose=1, steps=None)
    y = y_i[0][0]
    print('预测运行速度为', str(y*100), 'km/h')
    y_speed.append(y*100)


