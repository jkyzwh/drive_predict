library(XML)

drawout.STRUCTs.main <- function(FILE = "file", TYPE = "type")
{
    #-- global variables & constants ---
    inPath  = "G:/R/R"
    inFile  = "3.xml"
    outPath = "G:/R/R"
    
    doc <- xmlTreeParse(paste0(inPath,"/",inFile), useInternalNodes = TRUE)
    r <- xmlRoot(doc)
    
    #------------main loop -------------
    node <- r[[4]]
    for(i in 1:xmlSize(node)){
        # RoadName
        RoadName <- sub(" ", "", as.vector(xmlAttrs(node[[i]][[2]]))[attributes(xmlAttrs(node[[i]][[2]]))$names=='name'])
        RoadName <- iconv(RoadName, "utf-8", "gbk")

        # 输入的是C结构的xml node
        # 输出的是R结构的data.frame  
        Alignment <- get.Alignment.content(node[[i]])
        ParaCurve <- get.ParaCurve.content(node[[i]][[2]][[1]])
        CrossSects <- get.CrossSects.content(node[[i]][[3]])
        
        # 输入的data.frame看作是运行轨迹的局部信�?
        # 输出的data.frame看作是运行轨迹的完整信息
        RoadInformation_SE <- combine.RoadInformation_SE.content(Alignment, ParaCurve, CrossSects)
        RoadInformation_ES <- combine.RoadInformation_ES.content(RoadInformation_SE)

        #-- write tables ---
        dirName <- strsplit(inFile, split=".xml")[[1]]
        ifelse(dir.exists(dname <- paste0(outPath,"/",dirName)), NA, dir.create(dname))
        write.csv(ParaCurve, paste0(outPath,"/",dirName,"/",RoadName,"_ParaCurve.csv"), quote = FALSE, row.names = FALSE, na = "")
        write.csv(Alignment, paste0(outPath,"/",dirName,"/",RoadName,"_Alignment.csv"), quote = FALSE, row.names = FALSE, na = "")
        write.csv(CrossSects, paste0(outPath,"/",dirName,"/",RoadName,"_CrossSects.csv"), quote = FALSE, row.names = FALSE, na = "")
        write.csv(RoadInformation_SE, paste0(outPath,"/",dirName,"/",RoadName,"_RoadInformation(S-E).csv"), quote = FALSE, row.names = FALSE, na = "")
        write.csv(RoadInformation_ES, paste0(outPath,"/",dirName,"/",RoadName,"_RoadInformation(E-S).csv"), quote = FALSE, row.names = FALSE, na = "")
    }
    
    free(doc)
}

######################## get.Alignment.content ################################
###############################################################################
get.Alignment.content <- function(node)
{
    # 定义每一个字�?
    NO              <- c()            # 数据编号
    Road_Type       <- c()            # 路段类型
    K_Start         <- c()            # 本路段起点桩�?
    Length          <- c()            # 路段长度
    Radius          <- c()            # 圆曲线半�?
    Direction       <- c()            # 曲线转向
    DirStart        <- c()            # 起点方位�?
    DirEnd          <- c()            # 终点方位�?
    Chord           <- c()            # 曲线对应的弦�?
    delta_theta     <- c()            # 圆曲线或缓和曲线对应的转�?
    constant        <- c()            # 缓和曲线参数A
    Start_X         <- c()            # 路线起点X坐标
    Start_Y         <- c()            # 路线起点Y坐标
    End_X           <- c()            # 路线终点X坐标
    End_Y           <- c()            # 路线终点Y坐标
    Center_X        <- c()            # 曲线中心X坐标
    Center_Y        <- c()            # 曲线中心Y坐标

    # 遍历node
    n = xmlSize(node[[1]])
    for(i in 1:n)
    {
        staStart <- 0                       # 初始位置
        if(i==1)
        {
            v <- xmlAttrs(node)
            staStart <- as.double(as.vector(v)[attributes(v)$names=='staStart'])
        }
        
        NO[i]               <- i
        if(xmlName(node[[1]][[i]])=='Line')
        {
            v <- xmlAttrs(node[[1]][[i]])
            Road_Type[i]    <- 'Line'
            K_Start[i]      <- ifelse(is.null(K_Start), staStart, K_Start[i-1]+Length[i-1])
            Length[i]       <- as.double(as.vector(v)[attributes(v)$names=='length'])
            Radius[i]       <- NA
            Direction[i]    <- NA
            DirStart[i]     <- NA
            DirEnd[i]       <- NA
            Chord[i]        <- NA
            delta_theta[i]  <- NA
            constant[i]     <- NA
            s_t <- xmlValue(node[[1]][[i]][[1]])
            e_d <- xmlValue(node[[1]][[i]][[2]])
            Start_X[i]      <- as.double(strsplit(s_t,split=" ")[[1]][1])
            Start_Y[i]      <- as.double(strsplit(s_t,split=" ")[[1]][2])
            End_X[i]        <- as.double(strsplit(e_d,split=" ")[[1]][1])
            End_Y[i]        <- as.double(strsplit(e_d,split=" ")[[1]][2])
            Center_X[i]     <- NA
            Center_Y[i]     <- NA
        }
        else if(xmlName(node[[1]][[i]])=='Spiral')
        {
            v <- xmlAttrs(node[[1]][[i]])
            Road_Type[i]    <- 'Spiral'
            K_Start[i]      <- ifelse(is.null(K_Start), staStart, K_Start[i-1]+Length[i-1])
            Length[i]       <- as.double(as.vector(v)[attributes(v)$names=='length'])
            Radius[i]       <- NA
            Direction[i]    <- ifelse(as.vector(v)[attributes(v)$names=='rot']=='ccw', 'L', 'R')
            DirStart[i]     <- as.double(as.vector(v)[attributes(v)$names=='dirStart'])
            DirEnd[i]       <- as.double(as.vector(v)[attributes(v)$names=='dirEnd'])
            Chord[i]        <- as.double(as.vector(v)[attributes(v)$names=='chord'])
            delta_theta[i]  <- as.double(as.vector(v)[attributes(v)$names=='theta'])
            constant[i]     <- as.double(as.vector(v)[attributes(v)$names=='constant'])
            s_t <- xmlValue(node[[1]][[i]][[1]])
            e_d <- xmlValue(node[[1]][[i]][[2]])
            p_i <- xmlValue(node[[1]][[i]][[3]])
            Start_X[i]      <- as.double(strsplit(s_t,split=" ")[[1]][1])
            Start_Y[i]      <- as.double(strsplit(s_t,split=" ")[[1]][2])
            End_X[i]        <- as.double(strsplit(e_d,split=" ")[[1]][1])
            End_Y[i]        <- as.double(strsplit(e_d,split=" ")[[1]][2])
            Center_X[i]     <- as.double(strsplit(p_i,split=" ")[[1]][1])
            Center_Y[i]     <- as.double(strsplit(p_i,split=" ")[[1]][2])
        }
        else if(xmlName(node[[1]][[i]])=='Curve')
        {
            v <- xmlAttrs(node[[1]][[i]])
            Road_Type[i]    <- 'Curve'
            K_Start[i]      <- ifelse(is.null(K_Start), staStart, K_Start[i-1]+Length[i-1])
            Length[i]       <- as.double(as.vector(v)[attributes(v)$names=='length'])
            Radius[i]       <- as.double(as.vector(v)[attributes(v)$names=='radius'])
            Direction[i]    <- ifelse(as.vector(v)[attributes(v)$names=='rot']=='ccw', 'L', 'R')
            DirStart[i]     <- as.double(as.vector(v)[attributes(v)$names=='dirStart'])
            DirEnd[i]       <- as.double(as.vector(v)[attributes(v)$names=='dirEnd'])
            Chord[i]        <- as.double(as.vector(v)[attributes(v)$names=='chord'])
            delta_theta[i]  <- as.double(as.vector(v)[attributes(v)$names=='delta'])
            constant[i]     <- NA
            s_t <- xmlValue(node[[1]][[i]][[1]])
            e_d <- xmlValue(node[[1]][[i]][[2]])
            c_t <- xmlValue(node[[1]][[i]][[3]])
            Start_X[i]      <- as.double(strsplit(s_t,split=" ")[[1]][1])
            Start_Y[i]      <- as.double(strsplit(s_t,split=" ")[[1]][2])
            End_X[i]        <- as.double(strsplit(e_d,split=" ")[[1]][1])
            End_Y[i]        <- as.double(strsplit(e_d,split=" ")[[1]][2])
            Center_X[i]     <- as.double(strsplit(c_t,split=" ")[[1]][1])
            Center_Y[i]     <- as.double(strsplit(c_t,split=" ")[[1]][2])
        }
        else if(xmlName(node[[1]][[i]])=='IrregularLine')
        {
            v <- xmlAttrs(node[[1]][[i]])
            Road_Type[i]    <- 'IrregularLine'
            K_Start[i]      <- ifelse(is.null(K_Start), staStart, K_Start[i-1]+Length[i-1])
            Length[i]       <- as.double(as.vector(v)[attributes(v)$names=='length'])
            Radius[i]       <- NA
            Direction[i]    <- NA
            DirStart[i]     <- NA
            DirEnd[i]       <- NA
            Chord[i]        <- NA
            delta_theta[i]  <- NA
            constant[i]     <- NA
            s_t <- xmlValue(node[[1]][[i]][[1]])
            e_d <- xmlValue(node[[1]][[i]][[2]])
            Start_X[i]      <- as.double(strsplit(s_t,split=" ")[[1]][1])
            Start_Y[i]      <- as.double(strsplit(s_t,split=" ")[[1]][2])
            End_X[i]        <- as.double(strsplit(e_d,split=" ")[[1]][1])
            End_Y[i]        <- as.double(strsplit(e_d,split=" ")[[1]][2])
            Center_X[i]     <- NA
            Center_Y[i]     <- NA
        }
        else                # unknown type
        {
            Road_Type[i]    <- 'unknown'
            K_Start[i]      <- NA
            Length[i]       <- NA
            Radius[i]       <- NA
            Direction[i]    <- NA
            DirStart[i]     <- NA
            DirEnd[i]       <- NA
            Chord[i]        <- NA
            delta_theta[i]  <- NA
            constant[i]     <- NA
            Start_X[i]      <- NA
            Start_Y[i]      <- NA
            End_X[i]        <- NA
            End_Y[i]        <- NA
            Center_X[i]     <- NA
            Center_Y[i]     <- NA
        }
    }
    
    # 格式化输�?
    Length                  <- sapply(Length, round, digits = 2)
    K_Start                 <- sapply(K_Start, round, digits = 2)
    Radius                  <- sapply(Radius, round, digits = 2)
    DirStart                <- sapply(DirStart, round, digits = 2)
    DirEnd                  <- sapply(DirEnd, round, digits = 2)
    Chord                   <- sapply(Chord, round, digits = 2)
    delta_theta             <- sapply(delta_theta, round, digits = 2)
    constant                <- sapply(constant, round, digits = 2)
    Start_X                 <- sapply(Start_X, round, digits = 2)
    Start_Y                 <- sapply(Start_Y, round, digits = 2)
    End_X                   <- sapply(End_X, round, digits = 2)
    End_Y                   <- sapply(End_Y, round, digits = 2)
    Center_X                <- sapply(Center_X, round, digits = 2)
    Center_Y                <- sapply(Center_Y, round, digits = 2)

    return(data.frame(NO,Road_Type,K_Start,Length,Radius,Direction,DirStart,DirEnd,Chord,delta_theta,constant,Start_X,Start_Y,End_X,End_Y,Center_X,Center_Y))
}

######################## get.ParaCurve.content ################################
###############################################################################
get.ParaCurve.content <- function(node)
{
    # 定义每一个字�?
    NO          <- c()                  # 数据编号
    K_Start     <- c()                  # 变坡点桩�?
    Height      <- c()                  # 变坡点高�?
    VCL         <- c()                  # 双倍切线长
    i           <- c()                  # 纵坡坡度
    
    # 遍历node
    for(j in 1:xmlSize(node))
    {
        s <- xmlValue(node[[j]])
        v <- strsplit(s, split=" ")
        NO[j]       <- j
        K_Start[j]  <- as.double(v[[1]][1])
        Height[j]   <- as.double(v[[1]][2])
        VCL[j]      <- ifelse(j==1 | j==xmlSize(node), NA, as.double(as.vector(xmlAttrs(node[[j]]))[attributes(xmlAttrs(node[[j]]))$names=='length']))
        i[j]        <- ifelse(j==1, NA, (Height[j]-Height[j-1])/(K_Start[j]-K_Start[j-1]))
    }
    
    # 格式化输�?
    K_Start         <- sapply(K_Start, round, digits = 2)
    Height          <- sapply(Height, round, digits = 2)
    VCL             <- sapply(VCL, round, digits = 2)
    #i               <- sapply(i, function(x){ifelse(is.na(x), x, paste0(round(100*x,digits=2),"%"))})
    i               <- sapply(i, round, digits = 4)
    
    return(data.frame(NO,K_Start,Height,VCL,i))
}

######################## get.CrossSects.content ###############################
###############################################################################
get.CrossSects.content <- function(node)
{
    # 定义每一个字�?
    NO          <-c()           # 数据编号
    K_Start     <-c()           # 横断面变化点桩号
    CrossSect   <-c()           # 横断面名�?
    tunnel      <-c()           # 隧道断面标记 
    bridge      <-c()           # 桥梁断面标记
    Lane        <-c()           # 车道�?
    LaneWidth   <-c()           # 车道宽度
    RoadWidth   <-c()           # 路面总宽�?
    
    # 遍历node
    for(i in 1:xmlSize(node))
    {
        NO[i]           <- i
        v <- xmlAttrs(node[[i]])
        K_Start[i]      <- as.double(as.vector(v)[attributes(v)$names=='sta'])
        CrossSect[i]    <- as.vector(v)[attributes(v)$names=='name']
        # 中间变量
        name <- c()
        lanew <- c()
        roadw_1 <- 0
        roadw_2 <- 0
        for(j in 1:xmlSize(node[[i]]))
        {
            name_t <- as.vector(xmlAttrs(node[[i]][[j]]))[attributes(xmlAttrs(node[[i]][[j]]))$names=='name']
            name <- append(name, name_t)
            if(name_t == "roadway")
            {
                s_t <- xmlValue(node[[i]][[j]])
                v_t <- strsplit(s_t, split=" ")[[1]]
                lanew <- append(lanew, round((as.double(v_t[length(v_t)-1])-as.double(v_t[1])),digits=2))
            }
            if(j==1)
            {
                s_t <- xmlValue(node[[i]][[j]])
                v_t <- strsplit(s_t, split=" ")[[1]]
                roadw_1 <- as.double(v_t[1])
            }
        }
        for(j in xmlSize(node[[i]]):1)
        {
            name_t <- as.vector(xmlAttrs(node[[i]][[j]]))[attributes(xmlAttrs(node[[i]][[j]]))$names=='name']
            if(name_t != "tunnel" & name_t != "bridge")
            {
                s_t <- xmlValue(node[[i]][[j]])
                v_t <- strsplit(s_t, split=" ")[[1]]
                roadw_2 <- as.double(v_t[length(v_t)-1])
                break
            }
        }
        tunnel[i]       <- ifelse(length(which(name=="tunnel"))>0, "T", "F")
        bridge[i]       <- ifelse(length(which(name=="bridge"))>0, "T", "F")
        Lane[i]         <- length(which(name=="roadway"))
        LaneWidth[i]    <- gsub(", ", "/", toString(lanew))
        RoadWidth[i]    <- roadw_2-roadw_1
    }
    
    # 格式化输�?
    K_Start             <- sapply(K_Start, round, digits = 2)
    RoadWidth           <- sapply(RoadWidth, round, digits = 2)
    
    return(data.frame(NO,K_Start,CrossSect,tunnel,bridge,Lane,LaneWidth,RoadWidth))
}

#################### combine.RoadInformation_SE.content #######################
###############################################################################
combine.RoadInformation_SE.content <- function(Alignment, ParaCurve, CrossSects)
{
    # 定义每一个字段，并初始化
    K_data                      <- c()              # 路段桩号数据  
    Distance_from_Start         <- c()              # 距行驶路径起点的距离
    Road_Type                   <- c()              # 路段平曲线特�?
    Radius                      <- c()              # 圆曲线半�?
    Direction                   <- c()              # 曲线方向
    Height                      <- c()              # 变坡点高�?
    i                           <- c()              # 纵坡坡度
    CrossSect                   <- c()              # 横断面名�?
    tunnel                      <- c()              # 隧道断面标记
    bridge                      <- c()              # 桥梁断面标记
    Lane                        <- c()              # 车道�?
    
    max_n <- ceiling(max(c(Alignment[nrow(Alignment), 'K_Start'],ParaCurve[nrow(ParaCurve), 'K_Start'],CrossSects[nrow(CrossSects), 'K_Start']),na.rm=T))
    K_data                      <- 0:max_n
    Distance_from_Start         <- K_data
    Road_Type[max_n+1]          <- NA
    Radius[max_n+1]             <- NA
    Direction[max_n+1]          <- NA
    Height[max_n+1]             <- NA
    i[max_n+1]                  <- NA
    CrossSect[max_n+1]          <- NA
    tunnel[max_n+1]             <- NA
    bridge[max_n+1]             <- NA
    Lane[max_n+1]               <- NA
    
    # 遍历Alignment, ParaCurve, CrossSects
    for(j in 1:nrow(Alignment))
    {
        Road_Type[round(Alignment[j,'K_Start'])+1]    <- as.character(Alignment[j,'Road_Type'])
        Radius[round(Alignment[j,'K_Start'])+1]       <- Alignment[j,'Radius']
        Direction[round(Alignment[j,'K_Start'])+1]    <- as.character(Alignment[j,'Direction'])
    }
    for(j in 1:nrow(ParaCurve))
    {
        Height[round(ParaCurve[j,'K_Start'])+1]       <- ParaCurve[j,'Height']
        #i[round(ParaCurve[j,'K_Start'])+1]            <- as.character(ParaCurve[j,'i'])
        i[round(ParaCurve[j,'K_Start'])+1]            <- ParaCurve[j,'i']
    }
    for(j in 1:nrow(CrossSects))
    {
        CrossSect[round(CrossSects[j,'K_Start'])+1]   <- as.character(CrossSects[j,'CrossSect'])
        tunnel[round(CrossSects[j,'K_Start'])+1]      <- as.character(CrossSects[j,'tunnel'])
        bridge[round(CrossSects[j,'K_Start'])+1]      <- as.character(CrossSects[j,'bridge'])
        Lane[round(CrossSects[j,'K_Start'])+1]        <- CrossSects[j,'Lane']
    }

    # 返回
    return(data.frame(K_data,Distance_from_Start,Road_Type,Radius,Direction,Height,i,CrossSect,tunnel,bridge,Lane))
}

#################### combine.RoadInformation_ES.content #######################
###############################################################################
combine.RoadInformation_ES.content <- function(RoadInformation_SE)
{
    # 定义每一个字�?
    K_data                      <- c()              # 路段桩号数据  
    Distance_from_Start         <- c()              # 距行驶路径起点的距离
    Road_Type                   <- c()              # 路段平曲线特�?
    Radius                      <- c()              # 圆曲线半�?
    Direction                   <- c()              # 曲线方向
    Height                      <- c()              # 变坡点高�?
    i                           <- c()              # 纵坡坡度
    CrossSect                   <- c()              # 横断面名�?
    tunnel                      <- c()              # 隧道断面标记
    bridge                      <- c()              # 桥梁断面标记
    Lane                        <- c()              # 车道�?
    
    # Reverse Sort RoadInformation_SE
    order_n <- with(RoadInformation_SE, order(K_data, decreasing=TRUE))
    K_data                      <- RoadInformation_SE[order_n, 'K_data']
    Distance_from_Start         <- RoadInformation_SE['Distance_from_Start']
    Road_Type                   <- RoadInformation_SE[order_n, 'Road_Type']
    Radius                      <- RoadInformation_SE[order_n, 'Radius']
    Direction                   <- sapply(RoadInformation_SE[order_n, 'Direction'], function(x){ifelse(is.na(x), x, ifelse(x=="L", "R", "L"))})
    Height                      <- RoadInformation_SE[order_n, 'Height']
    #i                           <- sapply(RoadInformation_SE[order_n, 'i'], function(x){ifelse(is.na(x), x, ifelse(substr(x,1,1)=="-", substr(x,2,nchar(as.character(x))), paste0("-",x)))})
    i                           <- (-1)*RoadInformation_SE[order_n, 'i']
    CrossSect                   <- RoadInformation_SE[order_n, 'CrossSect']
    tunnel                      <- RoadInformation_SE[order_n, 'tunnel']
    bridge                      <- RoadInformation_SE[order_n, 'bridge']
    Lane                        <- RoadInformation_SE[order_n, 'Lane']
    
    # 移位处理
    # 第一组数据移动到第一�?, 其余数据依次移动到上一数据的位�?
    shift_i <- c()
    road_t <- which(!is.na(Road_Type))
    if(road_t[1]>1)
    {
        shift_i <- c(1, road_t)
    }
    else
    {
        sep <- which(diff(road_t)>1)[1]
        shift_i <- c(1, road_t[1:sep]+1, road_t[sep+1:length(road_t)])
    }
    for(j in 1:length(shift_i)-1)
    {
        Road_Type[shift_i[j]]     <- Road_Type[shift_i[j+1]]
        Radius[shift_i[j]]        <- Radius[shift_i[j+1]]
        Direction[shift_i[j]]     <- Direction[shift_i[j+1]]
        Road_Type[shift_i[j+1]]   <- NA
        Radius[shift_i[j+1]]      <- NA
        Direction[shift_i[j+1]]   <- NA
    }
    
    shift_i <- c()
    cross_s <- which(!is.na(CrossSect))
    if(cross_s[1]>1)
    {
        shift_i <- c(1, cross_s)
    }
    else
    {
        sep <- which(diff(cross_s)>1)[1]
        shift_i <- c(1, cross_s[1:sep]+1, cross_s[sep+1:length(cross_s)])
    }
    for(j in 1:length(shift_i)-1)
    {
        CrossSect[shift_i[j]]     <- CrossSect[shift_i[j+1]]
        tunnel[shift_i[j]]        <- tunnel[shift_i[j+1]]
        bridge[shift_i[j]]        <- bridge[shift_i[j+1]]
        Lane[shift_i[j]]          <- Lane[shift_i[j+1]]
        CrossSect[shift_i[j+1]]   <- NA
        tunnel[shift_i[j+1]]      <- NA
        bridge[shift_i[j+1]]      <- NA
        Lane[shift_i[j+1]]        <- NA
    }

    # 返回
    return(data.frame(K_data,Distance_from_Start,Road_Type,Radius,Direction,Height,i,CrossSect,tunnel,bridge,Lane))
}

drawout.STRUCTs.main()
