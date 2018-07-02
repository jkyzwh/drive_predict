#本脚本包含了一些基本的函数，包括：
# 1. 将试验数据按照等间距排列的Order.dis
#--------------------Order.dis 对道路编号相同的数据按照整桩号筛选，并排序------------------------------------------
# Dis 为代表桩号的列名，字符串类型（为了解决可能存在的列名不一致导致的运算问题）
# 示例：test_data<-Order.dis(test_data,"disFromRoadStart",step=1)
# 如果传入的DIS为时间，如Time，能实现对时间的排序
Order.dis <- function(data, Dis,step=1) 
{ # data为数据集，step为排列间距 
  data[[Dis]] <- as.numeric(data[[Dis]])
  data[[Dis]] <- data[[Dis]]%/%step*step 
  end=length(data[[Dis]])
  order <- c()
  for(i in 1:end)
  {
    if(i==1)
    {
      k=1
      order[1]=1
    }
    else if(data[[Dis]][i]!=data[[Dis]][i-1])
    {k=k+1
    order[k]=i
    }      
  }
  return(data[order,])
}









