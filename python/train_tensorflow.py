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

# '''
# 对每一列数据进行标准化
# '''
# # colnames = data_train.columns.values.tolist()
# data_train =data_train.drop(['driver_ID', 'Dis', 'k_location'], axis=1)
# # data_train = data_train.apply(lambda x: (x-np.min(x))/(np.max(x)-np.min(x)))
# data_test = data_test.drop(['driver_ID', 'Dis', 'k_location'], axis=1)
# # data_test = data_test.apply(lambda x: (x-np.min(x))/(np.max(x)-np.min(x)))

'''
将训练集和测试集均转化为numpy数组
'''

x_train = np.array(data_train.iloc[0:len(data_train), list(range(9, len(data_train.iloc[0])))])
y_train = np.array(data_train['Speed'])
len(x_train)-len(y_train)

x_test = np.array(data_test.iloc[0:len(data_test), list(range(9, len(data_test.iloc[0])))])
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
from keras.layers.core import Dense, Dropout, Activation, Flatten
from keras.layers.convolutional import Convolution2D, MaxPooling2D
from keras.preprocessing.image import ImageDataGenerator
from keras.optimizers import SGD, Adadelta, Adagrad
from keras.utils import np_utils, generic_utils
from keras.utils import plot_model




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