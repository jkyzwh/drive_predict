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

os.environ['KERAS_BACKEND'] = 'tensorflow'
import keras

import tensorflow as tf
import numpy as np

x_data = np.random.rand(100).astype(np.float32)
y_data = x_data * 0.1 + 0.3

Weights = tf.Variable(tf.random_uniform([1], -1.0, 1.0))
biases = tf.Variable(tf.zeros([1]))

y = Weights * x_data + biases

loss = tf.reduce_mean(tf.square(y-y_data))
optimizer = tf.train.GradientDescentOptimizer(0.5)
train = optimizer.minimize(loss)

init = tf.initialize_all_variables()


sess = tf.Session()
sess.run(init)


for step in range(5001):
    sess.run(train)
    if step % 10 ==0:
        print(step, sess.run(Weights), sess.run(biases))
sess.close()