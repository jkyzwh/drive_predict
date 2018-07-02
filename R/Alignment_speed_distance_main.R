# 程序功能说明----------------------------------------------------------------------------------------
#本源文件的功能是利用实验数据和机器学习方法测试利用实验数据和几何数据回归几何线形数据
#与驾驶行为数据的可能性
# 程序功能说明结束，程序中使用的函数与变量定义---------------------------------------------------------

packages_needed <- c('stats',
                     'rstudioapi',
                     'data.table',
                     'psych',
                     'rpart',
                     'ggplot2',
                     'ggthemes',
                     'devtools'
)
installed <- packages_needed %in% installed.packages()[, 'Package']

if (length(packages_needed[!installed]) >=1){
  install.packages(packages_needed[!installed])
}
rm(installed,packages_needed)
#0.0 获取当前脚本所在的目录名称----
# 便于加载位于同一目录下的其它文件
library(rstudioapi)    
file_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
OStype <- Sys.info()['sysname']

# 导入需要的标准函数功能源文件
library (stats)
library(stringr)

#加载位于上一级文件夹中的basicFun.R脚本文件，加载常用的基本函数，例如排序函数等
pass_off <- as.data.frame(str_locate_all(file_dir,"/"))
pass_off_2 <-pass_off$start[length(pass_off$start)]
#source(paste(str_sub(file_dir,1,pass_off_2),"basicFun.R",sep = ''))
#source(paste(str_sub(file_dir,1,pass_off_2),"DataInitialization.R",sep = ''))
source(paste(file_dir,"basicFun.R",sep = '/'))
source(paste(file_dir,"DataInitialization.R",sep = '/'))
source(paste(file_dir,"Alignment_speed_distance_fun.R",sep = '/'))

rm(pass_off,pass_off_2)
# 输入文件：
# 1. 驾驶模拟实验数据
# 2. 平曲线数据
# 3. 竖曲线、纵坡数据

# 1. 驾驶模拟实验数据导入 ##############
setwd("D:/PROdata/R/Acceleration Pretension/Data/S_Z")
temp<- list.files(pattern="*.csv")#查询当前目录下包含的所有csv文件，将文件名存入temp列表
data_name<-gsub('.csv','',temp)#将文件名的扩展名去掉，即将文件名中的.csv替换为空，存入data_name列表
for (i in 1:length(temp))
{
  #将每个读入csv生成的数据框赋值给对应的变量名
  assign(data_name[i], read.table(file=temp[i],header=T,sep=",",stringsAsFactors =FALSE ))
  aa<-get(data_name[i])
  # 数据列名称标准化
  aa<-fun_rename_data(aa)
  # 选择需要的数据列
  aa<-subset(aa, select=c("Time",         
                            "Dis",            
                            "Speed",          
                            "Acc_surge",      
                            "Acc_sway"
                            )
  )
  # 将数据列按照空间序列排序，间距为10秒，排序
  aa<-Order.dis(aa,step=10)
  # 增加ID列，将文件名的前两位（被试编号）赋值给driver_ID
  aa$driver_ID<-as.numeric(substr(data_name[i],1,2))
  # 将调整过的aa重新赋值给data_name对应的变量
  assign(data_name[i],aa)
}


# 将所有驾驶员数据整合成一张大表，区别不同驾驶员的数据标签为driver_ID
sim_alldata<-data.frame()
for (i in 1:length(data_name))
{
  #利用get()获取data_name中储存的变量名对应的变量，并赋值给中间变量aa
  aa<-get(data_name[i])
  #将变量一次连接，形成新的数据框
  sim_alldata<-rbind(aa,sim_alldata)
}

# 2. 平曲线数据导入 ##############
Road_Alignment<-read.table(file="D:/PROdata/R/Acceleration Pretension/Data/SZhighway_Alignment.csv",
                           header=T,sep=",",stringsAsFactors =FALSE )
# 2.1 将导入的平曲线数据进行校核
Road_Alignment<-alignment.check(Road_Alignment,2)

# 3. 竖曲线与纵坡数据导入 ##############
Road_ParaCurve<-read.table(file="D:/PROdata/R/Acceleration Pretension/Data/SZhighway_ParaCurve.csv",
                           header=T,sep=",",stringsAsFactors =FALSE )


# 4 定义训练数据集。为ID=1~4数据########
sim_learn_data<-subset(sim_alldata,driver_ID!=6)
sim_Test_data<-subset(sim_alldata,driver_ID==3)#利用其中一部分进行测试

#原始数据表生成
learn_data<-Sim_alignment.lm(sim_learn_data,Road_Alignment,Road_ParaCurve,800)
test_data<-Sim_alignment.lm(sim_Test_data,Road_Alignment,Road_ParaCurve,800)

#数据标准化
learn_data_n<-Sim_alignment.normalization(learn_data,max_speed=110,i_max=0.03,
                                          r_max=10000,acc_max=4.9,visual_distance=800)
test_data_n<-Sim_alignment.normalization(test_data,max_speed=110,i_max=0.03,
                                          r_max=10000,acc_max=4.9,visual_distance=800)

# 5. 相关关系的计算与可视化 #############################
#data_lm<-learn_data_n[,c(-20,-22)] #去掉字符变量，以便于做相关系数矩阵
#data_cor<-cor(data_lm)

# 利用psych包绘制相关系数与散点矩阵图
#library(psych)
#pairs.panels(data_lm)


# 6. 利用回归树进行数据集训练（speed~.....几何要素）##############################
library(rpart)
library(rpart.plot)
#利用决策树建立速度与几何参数的回归模型

speed_rpart_alignment<-rpart(speed~Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                            Angle_curve+drection_curve+D_next_i+next_i,
                            data=learn_data_n,method = "anova")
#决策树的可视化
rpart.plot(speed_rpart_alignment,digits=3,fallen.leaves = TRUE,type = 3,extra = 101)

# 对训练集进行速度预测
p.rpart_speed<-predict(speed_rpart_alignment,test_data_n) 

#对预测值进行平滑处理，平滑后的结果为speed_supersmooth$y
speed_supersmooth<-supsmu(test_data_n$Dis,p.rpart_speed,span = "cv", periodic = FALSE, bass = 0)

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,speed_supersmooth$y)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化

test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数


# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()



# 7.利用决策树进行速度预测（Ay~speed1+....几何要素）############
library(rpart)
library(rpart.plot)

speed_rpart_alignment<-rpart(Ay~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                               Angle_curve+drection_curve+D_next_i+next_i,
                             data=learn_data_n,method = "anova")
#决策树的可视化
rpart.plot(speed_rpart_alignment,digits=3,fallen.leaves = TRUE,type = 3,extra = 101)

# 对训练集进行速度预测
p.rpart_speed<-predict_Ay(test_data_n,speed_rpart_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.rpart_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)     #预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 7-B利用决策树进行速度预测（spped~Speed1+.....）############
library(rpart)
library(rpart.plot)

speed_rpart_alignment<-rpart(speed~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                               Angle_curve+drection_curve+D_next_i+next_i,
                             data=learn_data_n,method = "anova")
#决策树的可视化
rpart.plot(speed_rpart_alignment,digits=3,fallen.leaves = TRUE,type = 3,extra = 101)

# 对训练集进行速度预测
p.rpart_speed<-predict_speed(test_data_n,speed_rpart_alignment,step=10,speed0=0.83,max_speed=100,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.rpart_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)     #预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 8. 利用Bagging算法进行数据集训练（speed~几何要素）##############################
library(ipred)

#利用bagging函数建立速度与几何参数的回归模型

speed_bagging_alignment<-bagging(speed~Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                               Angle_curve+drection_curve+D_next_i+next_i,
                             data=learn_data_n,nbagg=5)

# 对训练集进行速度预测
p.bagging_speed<-predict(speed_bagging_alignment,test_data_n) 

#对预测值进行平滑处理，平滑后的结果为speed_supersmooth$y
speed_supersmooth<-supsmu(test_data_n$Dis,p.bagging_speed,span = "cv", periodic = FALSE, bass = 0)

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,speed_supersmooth$y)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化

test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 9.利用bagging函数进行速度预测（Ay~speed1+...几何要素）############

library(ipred)

#利用bagging函数建立速度与几何参数的回归模型

speed_bagging_alignment<-bagging(Ay~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                                   Angle_curve+drection_curve+D_next_i+next_i,
                                 data=learn_data_n,nbagg=10)

# 对训练集进行速度预测
p.bagging_speed<-predict_Ay(test_data_n,speed_bagging_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.bagging_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)     #预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 9-B.利用bagging函数进行速度预测（speed~speed1+...几何要素）############

library(ipred)

#利用bagging函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_bagging_alignment<-bagging(speed~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                                   Angle_curve+D_next_i+next_i,
                                 data=learn_data_n,nbagg=10)

# 对训练集进行速度预测
test_data_n<-na.omit(test_data_n)
p.bagging_speed<-predict_speed(test_data_n,speed_bagging_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.bagging_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)     #预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 10. 利用随机森林算法进行数据集训练（speed~几何要素）##############################
# 随机森林算法不支持非数值型变量，也不支持N/A数值

library(randomForest)  

#利用随机森林函数建立速度与几何参数的回归模型

speed_randomForest_alignment<-randomForest(speed~Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                                   Angle_curve+D_next_i+next_i,
                                 data=learn_data_n,na.action=na.omit)

# 对训练集进行速度预测
p.randomForest_speed<-predict(speed_randomForest_alignment,test_data_n) 

#对预测值进行平滑处理，平滑后的结果为speed_supersmooth$y
speed_supersmooth<-supsmu(test_data_n$Dis,p.randomForest_speed,span = "cv", periodic = FALSE, bass = 0)

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.randomForest_speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 11.利用随机森林进行速度预测（Ay~speed1+几何要素）############
# 随机森林算法不支持非数值型变量，也不支持N/A数值
library(randomForest)

speed_randomForest_alignment<-randomForest(Ay~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                                             Angle_curve+D_next_i+next_i,
                                           data=learn_data_n,na.action=na.omit)
# 对训练集进行速度预测
p.randomForest_speed<-predict_Ay(test_data_n,speed_randomForest_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.randomForest_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 11-B.利用随机森林进行速度预测（speed~speed1+几何要素）############
# 随机森林算法不支持非数值型变量，也不支持N/A数值
library(randomForest)

speed_randomForest_alignment<-randomForest(speed~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                                             Angle_curve+D_next_i+next_i,
                                           data=learn_data_n,na.action=na.omit)
# 对训练集进行速度预测
p.randomForest_speed<-predict_speed(test_data_n,speed_randomForest_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.randomForest_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))



# 12. 利用MARS算法进行数据集训练（speed~几何要素）##############################
# MARS算法不支持非数值型变量，也不支持N/A数值

library(earth)  

#利用earth函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_MARS_alignment<-earth(speed~Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                                             Angle_curve+D_next_i+next_i,
                                           data=learn_data_n)

# 对训练集进行速度预测
p.MARS_speed<-predict(speed_MARS_alignment,test_data_n) 

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.MARS_speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 13.利用MARS进行速度预测（Ay~speed1+几何要素）############
# MARS算法不支持非数值型变量，也不支持N/A数值
library(earth)  

#利用earth函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_MARS_alignment<-earth(Ay~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                              Angle_curve+D_next_i+next_i,
                            data=learn_data_n)

# 对训练集进行速度预测
p.MARS_speed<-predict_Ay(test_data_n,speed_MARS_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.MARS_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 13-B.利用MARS进行速度预测（speed~speed1+几何要素）############
# MARS算法不支持非数值型变量，也不支持N/A数值
library(earth)  

#利用earth函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_MARS_alignment<-earth(speed~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                              Angle_curve+D_next_i+next_i,
                            data=learn_data_n)

# 对训练集进行速度预测
p.MARS_speed<-predict_speed(test_data_n,speed_MARS_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.MARS_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

# 14. 利用神经网络算法进行数据集训练（speed~几何要素）##############################

library(nnet)  

#利用earth函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_nnet_alignment<-nnet(speed~Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                              Angle_curve+D_next_i+next_i,data=learn_data_n,
                           size=21,skip=TRUE,linout=TRUE,decay=0.025)

# 对训练集进行速度预测
p.nnet_speed<-predict(speed_nnet_alignment,test_data_n) 

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.nnet_speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()


# 15.利用神经网络算法进行速度预测（Ay~speed1+几何要素）############

library(nnet)  

#利用nnet函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_nnet_alignment<-nnet(Ay~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                             Angle_curve+D_next_i+next_i,
                           data=learn_data_n,
                           size=0,skip=TRUE,linout=TRUE,decay=0.025)

# 对训练集进行速度预测
p.nnet_speed<-predict_Ay(test_data_n,speed_nnet_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.nnet_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 15-B.利用神经网络算法进行速度预测（speed~speed1+.....）############

library(nnet)  

#利用nnet函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_nnet_alignment<-nnet(speed~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                             Angle_curve+D_next_i+next_i,
                           data=learn_data_n,
                           size=30,skip=TRUE,linout=TRUE,decay=0.025)

# 对训练集进行速度预测
p.nnet_speed<-predict_speed(test_data_n,speed_nnet_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.nnet_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

# 16. 利用投影寻踪算法进行数据集训练（speed~几何要素）##############################


#利用ppr函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_ppr_alignment<-ppr(speed~Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                             Angle_curve+D_next_i+next_i,data=learn_data_n,
                           nterms=10)

# 对训练集进行速度预测
test_data_n<-na.omit(test_data_n)
p.ppr_speed<-predict(speed_ppr_alignment,test_data_n) 

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.ppr_speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

ggplot(data=test_out_view,aes(x=Dis,y=MAE))+geom_line()

# 17.利用投影寻踪算法进行速度预测（Ay~speed1+几何要素）############


#利用ppr函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_ppr_alignment<-ppr(Ay~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                             Angle_curve+D_next_i+next_i,
                           data=learn_data_n,nterms=50)

# 对训练集进行速度预测
test_data_n<-na.omit(test_data_n)
p.ppr_speed<-predict_Ay(test_data_n,speed_ppr_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.ppr_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))

# 17-B.利用投影寻踪算法进行速度预测（speed~speed1+.....）############


#利用ppr函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_ppr_alignment<-ppr(speed~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                           Angle_curve+D_next_i+next_i,
                         data=learn_data_n,nterms=10)

# 对训练集进行速度预测
test_data_n<-na.omit(test_data_n)
p.ppr_speed<-predict_speed(test_data_n,speed_ppr_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.ppr_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))


# 18. 利用支持向量机算法进行数据集训练（speed~...几何要素）##############################

library(e1071)
#利用svm函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_svm_alignment<-svm(speed~Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                           Angle_curve+D_next_i+next_i,data=learn_data_n,
                         method = "C-classification", kernel = "polynomial")

# 对训练集进行速度预测
test_data_n<-na.omit(test_data_n)
p.svm_speed<-predict(speed_svm_alignment,test_data_n) 

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.svm_speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))


# 19.利用支持向量机算法进行速度预测（Ay~speed1+几何要素）############
library(e1071)

#利用svm函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_svm_alignment<-svm(Ay~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                           Angle_curve+D_next_i+next_i,data=learn_data_n,
                         method = "C-classification", kernel = "polynomial")

# 对训练集进行速度预测
test_data_n<-na.omit(test_data_n)
p.svm_speed<-predict_Ay(test_data_n,speed_svm_alignment,step=10,speed0=0.83,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.svm_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))


# 19-B.利用支持向量机算法进行速度预测（speed~speed1+....几何要素）############
library(e1071)

#利用svm函数建立速度与几何参数的回归模型
learn_data_n<-na.omit(learn_data_n)
speed_svm_alignment<-svm(speed~Speed1+Now_i+Now_curve_R+D_curve+R_curve+L_curve+
                           Angle_curve+D_next_i+next_i,data=learn_data_n,
                         method = "C-classification", kernel = "polynomial")

# 对训练集进行速度预测
test_data_n<-na.omit(test_data_n)
p.svm_speed<-predict_speed(test_data_n,speed_svm_alignment,step=10,speed0=0.5,max_speed=120,acc_max=4.9)#预测测试集

#实际结果与预测值的汇总描述
test_out_view<-subset(test_data_n,select=c("Time","Dis","speed"))
test_out_view<-cbind(test_out_view,p.svm_speed$speed)
# 剔除数据中的N/A数值
test_out_view<-na.omit(test_out_view)
test_name<-c("Time","Dis","speed","predict")
names(test_out_view)<-test_name #变量名规范化
# 预测数据平滑处理
speed_supersmooth<-supsmu(test_out_view$Dis,test_out_view$predict,span = "cv", periodic = FALSE, bass = 0)
test_out_view$predict<-speed_supersmooth$y
test_out_view<-subset(test_out_view,Dis>2000 & Dis<25000)

# 预测精度校验
summary(test_out_view$speed) #实际值描述
summary(test_out_view$predict)#预测值描述
cor(test_out_view$speed,test_out_view$predict)  #预测值与实际值线性相关系数

# 实际值与预测值的差异性比对

test_out_view$speed<-test_out_view$speed*120
test_out_view$predict<-test_out_view$predict*120
test_out_view$MAE<-abs(test_out_view$speed-test_out_view$predict)
mean(test_out_view$MAE)

#实际值与预测值的可视化比对
library(ggplot2)
p<-ggplot(data=test_out_view,aes(x=Dis,y=speed))+geom_line()
p+geom_line(data=test_out_view,aes(x=Dis,y=predict,colour="red"))
