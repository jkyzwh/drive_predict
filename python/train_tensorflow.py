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
data_train = training_data[training_data['driver_ID'] != ID_list[0]]
data_test = training_data[training_data['driver_ID'] == ID_list[0]]

# SettingWithCopyWarning: 警告的解决方式
data_train.loc[:, 'Speed'] = data_train['Speed'].apply(lambda x: (x/SPEED_LIMIT))
data_train.loc[:, 'speed_lastlocation'] = data_train['speed_lastlocation'].apply(lambda x: (x/SPEED_LIMIT))
data_train.loc[:, 'speed_limit'] = data_train['speed_limit'].apply(lambda x: (x/SPEED_LIMIT))

data_test.loc[:, 'Speed'] = data_test['Speed'].apply(lambda x: (x/SPEED_LIMIT))
data_test.loc[:, 'speed_lastlocation'] = data_test['speed_lastlocation'].apply(lambda x: (x/SPEED_LIMIT))
data_test.loc[:, 'speed_limit'] = data_test['speed_limit'].apply(lambda x: (x/SPEED_LIMIT))

# # colnames = data_train.columns.values.tolist()


'''
将训练集和测试集均转化为numpy数组
'''
data_train =data_train.drop(['driver_ID', 'Dis', 'k_location', "Acc_surge", "Acc_sway", 'Steering',
             'Acc_pedal', 'Brake_pedal'], axis=1)
data_test = data_test.drop(['driver_ID', 'Dis', 'k_location', "Acc_surge", "Acc_sway", 'Steering',
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
'''

import keras
from keras.models import Sequential
from keras.layers.core import Dense, Activation
from keras.optimizers import SGD, Adadelta, Adagrad, RMSprop
from keras.layers import Dropout
from keras import metrics

# from keras.utils import np_utils  #用于分类器的矢量编码

np.random.seed(1671)

# 隐藏层神经元数量
N_HIDDEN = 320
BATCH_SIZE = 120


only_alignmentModel = Sequential()

# 输入层

only_alignmentModel.add(Dense(units=N_HIDDEN, input_dim=677))
only_alignmentModel.add(Activation('relu'))


# 隐藏层

only_alignmentModel.add(Dense(N_HIDDEN))
only_alignmentModel.add(Activation('relu'))
only_alignmentModel.add(Dropout(0.2))

only_alignmentModel.add(Dense(N_HIDDEN))
only_alignmentModel.add(Activation('relu'))
only_alignmentModel.add(Dropout(0.2))

# only_alignmentModel.add(Dense(N_HIDDEN))
# only_alignmentModel.add(Activation('relu'))
# only_alignmentModel.add(Dropout(0.2))
#
# only_alignmentModel.add(Dense(N_HIDDEN))
# only_alignmentModel.add(Activation('relu'))
# only_alignmentModel.add(Dropout(0.2))

# 输出层

only_alignmentModel.add(Dense(1))
only_alignmentModel.add(Activation('sigmoid'))

'''
在训练模型之前，您需要配置学习过程，这是通过 compile 方法完成的。它接收三个参数：
优化器 optimizer。它可以是现有优化器的字符串标识符，如 rmsprop 或 adagrad，也可以是 Optimizer 类的实例。详见：optimizers。
损失函数 loss，模型试图最小化的目标函数。它可以是现有损失函数的字符串标识符，如 categorical_crossentropy 或  mse，也可以是一个目标函数。详见：losses。
评估标准 metrics。对于任何分类问题，你都希望将其设置为 metrics = ['accuracy']。评估标准可以是现有的标准的字符串标识符，也可以是自定义的评估标准函数。
'''
# 定义评估函数
def Y_pred(y_true, y_pred):
    return y_pred*100

def Y_true(y_true, y_pred):
    return y_true*100

def plus_pred(y_true, y_pred):
    return (y_pred-y_true)*100

def correct_rates(y_true, y_pred):
    return (y_pred-y_true)*100/y_true

only_alignmentModel.compile(
    # loss='mean_squared_error',
    loss='mean_absolute_error',
    optimizer='RMSprop',
    metrics=['accuracy', Y_pred, Y_true, plus_pred, correct_rates]
)


'''
训练神经网络
'''
first_keras = only_alignmentModel.fit(
    x_train, y_train,
    batch_size=BATCH_SIZE,
    epochs=20,
    verbose=1,
    validation_split=0.2
)

score = only_alignmentModel.evaluate(x_test, y_test, verbose=1)

print("test score", score[0])
print("测试准确率是", score[1])




# x_data = np.random.rand(100).astype(np.float32)
# y_data = x_data * x_data * 0.1 + 0.3
#
# Weights = tf.Variable(tf.random_uniform([1], -1.0, 1.0))
# biases = tf.Variable(tf.zeros([1]))
#
# y = Weights * x_data + biases
#
# loss = tf.reduce_mean(tf.square(y-y_data))
# optimizer = tf.train.GradientDescentOptimizer(0.5)
# train = optimizer.minimize(loss)
#
# init = tf.initialize_all_variables()
#
#
# sess = tf.Session()
# sess.run(init)
#
#
# for step in range(5001):
#     sess.run(train)
#     if step % 10 == 0:
#         print(step, sess.run(Weights), sess.run(biases))
# sess.close()