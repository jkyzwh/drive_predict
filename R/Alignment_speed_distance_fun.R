#-------------
packages_needed <- c('psych',
                     'rpart',
                     'rpart.plot',
                     'ggplot2',
                     'ggthemes',
                     'devtools'
)
installed <- packages_needed %in% installed.packages()[, 'Package']

if (length(packages_needed[!installed]) >=1){
  install.packages(packages_needed[!installed])
}
rm(installed,packages_needed)

# load packages needed
library(psych)
library(rpart)
library(rpart.plot)

# 1. fun_rename_data: 原始数据数据列名的标准化-----------------
#函数使用条件为已经完成了驾驶模拟实验数据的导入
#函数的基本功能为替换为更容易理解的变量名

fun_rename_data<- function(data) 
{ #data为导入的原始数据
  #为数据框各列重新命名为简洁易理解的名字
  data_name<- c("Time",                     # 锘縠lapsed.time.s.,       # 场景时间，s
                "Time_carsim",              # CarSim.TruckSim.time.s.,  # CarSim/TruckSim时间，s
                "Ab_time",                  # absolute.time,            # 主机电脑时间，hh:mm:ss:ms
                "Car_type",                 # car.type,                 # 车型
                "Car_name",                 # name,                     # 车辆名称
                "ID",                       # ID,
                "Position_x",               # position.x.,              # 世界坐标系x坐标
                "Position_y",               # position.y.,              # 世界坐标系y坐标
                "Position_z",               # position.z.,              # 世界坐标系z坐标
                "Direction_x",              # direction.x.,
                "Direction_y",              # direction.y.,
                "Direction_z",              # direction.z.,
                "Yaw",                      # yaw.rad.,                 # 偏航角，rad
                "Pitch",                    # pitch.rad.,               # 纵摇角，rad
                "Roll",                     # roll.rad.,                # 翻滚角，rad
                "Intersection",             # in.intersection,          # 是否为交叉口
                "Rd",                       # road,                     # 道路名称
                "Dis",                      # distance.from.road.start, # 距离道路起点位置，m
                "Rd_width",                 # carriage.way.width,       # 模拟车所在道路宽度，m
                "Left_bd",                  # left.border.distance,     # 模拟车距离道路左侧边缘位置，m
                "Right_bd",                 # right.border.distance,    # 模拟车距离道路右侧边缘位置，m
                "Tral_dis",                 # traveled.distance,        # 模拟车行驶距离，m
                "Lane_dir",                 # lane.direction.rad.,      # 道路方向，rad
                "Lane_num",                 # lane.number,              # 模拟车所在车道号
                "Lane_width",               # lane.width,               # 模拟车所在车道宽度，m
                "Lane_offset",              # lane.offset,              # 模拟车偏离所在车道中心线距离，m
                "Rd_offset",                # road.offset,              # 模拟车偏离所在道路中心线距离，m
                "Lateral_slope",            # road.lateral.slope.rad.,  # 道路横坡，rad
                "Longitudinal_slope",       # road.longitudinal.slope,  # 道路纵坡
                "Gear",                     # gear,                     # 模拟车行驶档位
                "Light",                    # light.status,             # 车灯状态
                "RPM",                      # rpm,                      # 模拟车转速
                "Speed",                    # speed.m.s.,               # 车速，m/s
                "Speed_x",                  # speed.vector_x.m.s.,      # 车速在x方向分量，m/s
                "Speed_y",                  # speed.vector_y.m.s.,      # 车速在y方向分量，m/s
                "Speed_z",                  # speed.vector_z.m.s.,      # 车速在z方向分量，m/s
                "Acc_sway",                 # local.acceleration_sway.m.s.2.,            # 模拟车横向加速度，m/s^2
                "Acc_heave",                # local.acceleration_heave.m.s.2.,           # 模拟车垂直加速度，m/s^2
                "Acc_surge",                # local.acceleration_surge.m.s.2.,           # 模拟车纵向加速度，m/s^2
                "Yaw_speed",                # rotation.speed_yaw.rad.s.,                 # 模拟车yaw角速度，rad/s
                "Pitch_speed",              # rotation.speed_pitch.rad.s.,               # 模拟车pitch角速度，rad/s
                "Roll_speed",               # rotation.speed_roll.rad.s.,                # 模拟车roll角速度，rad/s
                "Acc_yaw",                  # rotation.acceleration_yaw.rad.s.2.,        # 模拟车yaw角加速度，rad/s^2
                "Acc_pitch",                # rotation.acceleration_pitch.rad.s.2.,      # 模拟车pitch角加速度，rad/s^2
                "Acc_roll",                 # rotation.acceleration_roll.rad.s.2.,       # 模拟车roll角加速度，rad/s^2
                "Steering",                 # steering,                 # 方向盘转角
                "Acc_pedal",                # acceleration.pedal,       # 加速踏板踩踏深度
                "Brake_pedal",              # brake.pedal,              # 制动踏板踩踏深度
                "Clutch_pedal",             # clutch.pedal,             # 离合踏板踩踏深度
                "Hand_brake",               # hand.brake,               # 手刹状态
                "Key",                      # ignition.key,             # 钥匙开关是否激活
                "Gear_level",               # gear.lever,               # 模拟车行驶档位
                "Wiper",                    # wiper,                    # 雨刷状态
                "Horn",                     # horn,                     # 喇叭状态
                "Car_weight",               # car.weight.kg.,           # 模拟车质量，kg
                "Car_wheelbase",            # car.wheelbase,            # 模拟车轴距，m
                "Car_width",                # car.width,                # 模拟车宽度，m
                "Car_length",               # car.length,               # 模拟车长度，m
                "Car_height",               # car.height,               # 模拟车高度，m
                "front_left_wheel_x",
                "front_left_wheel_y",
                "front_right_wheel_x",
                "front_right_wheel_y",
                "rear_left_wheel_x",
                "rear_left_wheel_y",
                "rear_right_wheel_x",
                "rear_right_wheel_y",
                "TTC_front",                # front.vehicle.TTC.s.,       # 前车TTC，车速小于前车，输出n/a
                "Dis_front",                # front.vehicle.distance.m.,  # 前车距离
                "TTC_rear",                 # rear.vehicle.TTC.s.,        # 后车TTC
                "Dis_rear",                 # rear.vehicle.distance.m.,   # 后车距离
                "Speed_rear",               # rear.vehicle.speed.m.s.,    # 后车速度，m/s
                "road_bumps",
                "Scen"                      # scenario.name               # 场景名称
  )
  names(data) <- data_name
  return(data)
}

# 2. 按桩号排列数据  ####    
Order.dis <- function(data, step=1){      # data为数据集，step为排列间距
  data$Dis <- data$Dis%/%step*step 
  end=length(data$Dis)
  order <- c()
  for(i in 1:end){
    if(i==1){
      k=1
      order[1]=1
    }
    else if(data$Dis[i]!=data$Dis[i-1])
    {k=k+1
    order[k]=i
    }      
  }
  return(data[order,])
}


# 3. 按时间排列数据 #####
Order.time <- function(data, step=1){     # data为数据集，step为排列间距
  data$Time <- data$Time%/%step*step 
  end <- length(data$Time)
  order <- c()
  for(i in 1:end){
    if(i==1){
      k=1
      order[1]=1
    }
    else if(data$Time[i]!=data$Time[i-1])
    {k=k+1
    order[k]=i
    }      
  }
  return(data[order,])
}

# 4. 对平曲线表进行校核####
# 将计算误差导致的极短直线就行修正,对所有的线元进行半径赋值

alignment.check<-function(alignment_data,L=5)#L是用于判断需要修正的长度
{
  A<-alignment_data
  drop<-c()
  for ( i in 1:(length(A$K_Start)-2))
  {
    if(A$Length[i]<=L) 
    {
      drop<-append(drop,(0-i))
      A$K_Start[i+1]<-A$K_Start[i]
      A$Length[i+1]<-A$K_Start[i+2]-A$K_Start[i+1]
    }
  }
 A<-A[drop,] #将极短直线删除
 # 为直线和缓和曲线半径赋值，对直线转角赋值为PI
 for ( i in 1:length(A$K_Start)) 
 {
   if(A$Road_Type[i]=="Line")
   {
     A$Radius[i]<-10000
     A$delta_theta[i]<-pi
     A$Direction[i]<-"S"
   }
   
   if(A$Road_Type[i]=="Spiral")
   {
     if(A$Road_Type[i+1]=="Line") A$Radius[i]<-(10000+A$Radius[i-1])/2
     if(A$Road_Type[i+1]=="Curve") A$Radius[i]<-(10000+A$Radius[i+1])/2
    }
 }
 return(A)
}


# 5. 将sim原始数据+alignment数据转换为可用于回归分析的数据表 ##############
#sim_data是驾驶模拟器排序后的数据（时间或者空间排序）
#alignment_data是平曲线数据表,ParaCurve_data 竖曲线文件

Sim_alignment.lm<-function(sim_data,alignment_data,ParaCurve_data,visual_distance=800)
{
  data_test<-data.frame(Time=0,Dis=0,speed=0,Ay=0,Ax=0,Ay1=0,Ay2=0,Ay3=0,Speed1=0,Speed2=0,Speed3=0,
                        Ax1=0,Ax2=0,Ax3=0)
  # Ay是纵向加速度，Ax为横向加速度，Ay1代表前1秒加速度数值，speed1和Ax1以以此例推
  sim<-sim_data
  sim$Speed<-sim$Speed*3.6
  Road_Alignment<-alignment_data
  V_D<-visual_distance
  
  for (i in 4:length(sim$Time))
  {
    aa<-c(0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    aa[1]<-sim$Time[i]
    aa[2]<-sim$Dis[i]
    aa[3]<-sim$Speed[i]
    aa[4]<-sim$Acc_surge[i]
    aa[5]<-sim$Acc_sway[i]
    aa[6]<-sim$Acc_surge[i-1]
    aa[7]<-sim$Acc_surge[i-2]
    aa[8]<-sim$Acc_surge[i-3]
    aa[9]<-sim$Speed[i-1]
    aa[10]<-sim$Speed[i-2]
    aa[11]<-sim$Speed[i-3]
    aa[12]<-sim$Acc_sway[i-1]
    aa[13]<-sim$Acc_sway[i-2]
    aa[14]<-sim$Acc_sway[i-3]
    data_test<-rbind(data_test,aa)
  }
  data_test<-data_test[c(-1),]
  #5.0 增加道路几何参数的数据项############
  # 预定义几何参数的数据项
  data_test$Now_curve_R<-0       #当前行驶半径，直线段使用10000米
  data_test$Now_i<-0             #当前行驶路段纵坡
  data_test$D_curve<-0           #前方曲线起点距离
  data_test$R_curve<-0           #前方平曲线半径
  data_test$L_curve<-0           #前方平曲线长度
  data_test$T_curve<-0           #前方平曲线类型
  data_test$Angle_curve<-pi      #前方平曲线交角
  data_test$drection_curve<-"S"  #前方平曲线转角方向
  data_test$D_next_i<-0          #下一路段纵坡变坡点距离
  data_test$next_i<-0            #下一路段纵坡坡度
  
  
  #5.1 获取当前行驶桩号处平曲线信息，视野内下一单元平曲线信息 ###############
  for (i in 1:length(data_test$Dis))
  {
    D<-data_test$Dis[i]
    station<-D+V_D
    
    for ( j in 1:(length(Road_Alignment$K_Start)-1))
    {
      if(Road_Alignment$K_Start[j]<=D && D<Road_Alignment$K_Start[j]+Road_Alignment$Length[j]) 
      {
        data_test$Now_curve_R[i]<-Road_Alignment$Radius[j]
        # 判断下一曲线单元起点与驾驶人视野之间的关系
        if(Road_Alignment$K_Start[j+1]<station)
        {
          data_test$D_curve[i]<-Road_Alignment$K_Start[j+1]-D         #前方曲线起点距离
          data_test$R_curve[i]<-Road_Alignment$Radius[j+1]              #前方平曲线半径
          data_test$L_curve[i]<-station - Road_Alignment$K_Start[j+1]   #前方平曲线长度
          data_test$T_curve[i]<-Road_Alignment$Road_Type[j+1]           #前方平曲线类型
          data_test$Angle_curve[i]<-Road_Alignment$delta_theta[j+1]     #前方平曲线交角
          data_test$drection_curve[i]<-Road_Alignment$Direction[j+1]    #前方平曲线方向
        }
        if(Road_Alignment$K_Start[j+1]>=station)
        {
          data_test$D_curve[i]<-V_D                                   #前方曲线起点距离
          data_test$R_curve[i]<-Road_Alignment$Radius[j]              #前方平曲线半径
          data_test$L_curve[i]<-0                                     #前方平曲线长度
          data_test$T_curve[i]<-Road_Alignment$Road_Type[j]           #前方平曲线类型
          data_test$Angle_curve[i]<-Road_Alignment$delta_theta[j]     #前方平曲线交角
          data_test$drection_curve[i]<-Road_Alignment$Direction[j]    #前方平曲线方向
        }
        break
      }
    }
  }
  
  #5.2 获取当前行驶桩号处纵坡信息，视野内下一坡度信息 ###############
  for (i in 1:length(data_test$Dis))
  {
    station<-data_test$Dis[i] 
    
    for ( j in 1:(length(ParaCurve_data$K_Start)-1))
    {
      if(ParaCurve_data$K_Start[j]<=station & station<ParaCurve_data$K_Start[j+1]) 
      {
        data_test$Now_i[i]<-ParaCurve_data$i[j+1]
        # 判断视野范围内是否存在变坡点
        if(ParaCurve_data$K_Start[j+1]<(station+V_D))
        {
          data_test$D_next_i[i]<-ParaCurve_data$K_Start[j+1]-station    #下一路段纵坡变坡点距离
          data_test$next_i[i]<-ParaCurve_data$i[j+2]              #下一路段纵坡坡度
        }
        else
        {
          data_test$D_next_i[i]<-0    #下一路段纵坡变坡点距离
          data_test$next_i[i]<-ParaCurve_data$i[j+1]              #下一路段纵坡坡度
        }
        break
      }
    }
  }
  
return(data_test)
}

#6. 对用于机器学习训练和测试的数据集进行标准化工作#######

Sim_alignment.normalization<-function(lm.data,max_speed=120,i_max=0.1,r_max=10000,
                                      acc_max=4.9,visual_distance=800)
{
  data<-lm.data
  
  data$speed<-data$speed/max_speed
  data$Speed1<-data$Speed1/max_speed
  data$Speed2<-data$Speed2/max_speed
  data$Speed3<-data$Speed3/max_speed
  
  data$Ay<-data$Ay/acc_max
  data$Ay1<-data$Ay1/acc_max
  data$Ay1<-data$Ay1/acc_max
  data$Ay1<-data$Ay1/acc_max
  
  data$Ax<-data$Ax/acc_max
  data$Ax1<-data$Ax1/acc_max
  data$Ax2<-data$Ax2/acc_max
  data$Ax3<-data$Ax3/acc_max
  
  data$Now_curve_R<-data$Now_curve_R/r_max
  data$R_curve<-data$R_curve/r_max
  data$Now_i<-data$Now_i/i_max
  data$D_curve<-data$D_curve/visual_distance
  data$L_curve<-data$L_curve/visual_distance
  data$Angle_curve<- data$Angle_curve/pi
  data$D_next_i<-data$D_next_i/visual_distance
  data$next_i<-data$next_i/i_max    
  
  return(data)
  
}

# 7. 利用考虑前一秒速度的回归树预测加速度##############

predict_Ay<-function(test.data,p.rpart,step=10,speed0=0.8,max_speed=120,acc_max=4.9)
  #函数参数为测试集数据集，以及回归树预测结果,初始速度为0.8倍最高速度
{
  end=length(test.data$Dis)
  for(i in 1:end)
  {
    test<-test.data[c(i),]
    if(i==1)
    {
      test$Speed1<-speed0
      test.data$Ay[i]<-predict(p.rpart,test)
      
      v2<-speed0*max_speed/3.6
      a<-test.data$Ay[i]*acc_max
      v1<-sqrt(v2*v2+2*a*step)
      
      test.data$speed[i]<-v1*3.6/max_speed
     
    }
    else
    {
      test$Speed1<-test.data$speed[i-1]
      test.data$Speed1[i]<-test.data$speed[i-1]
      test.data$Ay[i]<-predict(p.rpart,test)
      
      v2<-test.data$Speed1[i]*max_speed/3.6
      a<-test.data$Ay[i]*acc_max
      v1<-sqrt(v2*v2+2*a*step)
      
      test.data$speed[i]<-v1*3.6/max_speed
      
     # print(i)
    }
  }
  return(test.data)
}

# 8. 利用考虑前一秒速度直接预测速度##############

predict_speed<-function(test.data,p.rpart,step=10,speed0=0.8,max_speed=120,acc_max=4.9)
  #函数参数为测试集数据集，以及回归树预测结果,初始速度为0.8倍最高速度
{
  end=length(test.data$Dis)
  for(i in 1:end)
  {
    test<-test.data[c(i),]
    if(i==1)
    {
      test$Speed1<-speed0
      test.data$speed[i]<-predict(p.rpart,test)
      
     
    }
    else
    {
      test$Speed1<-test.data$speed[i-1]
      test.data$Speed1[i]<-test.data$speed[i-1]
      test.data$speed[i]<-predict(p.rpart,test)
      
      # print(test)
    }
  }
  return(test.data)
}