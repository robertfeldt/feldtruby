source("boxcox.R")
source("myfunctions.R")
#library(rgl) # for 3-D view
# generate swiss roll data
v <- rep(c(1:5, seq(6,10,len=10), seq(10.5, 15,len=15)), rep(5, 30))/20
u <- rep(1:5, 30)/20
n <- length(v)
x <- 1/2*v*sin(4*pi*v); y <- u-1/2; z <- 1/2*v*cos(4*pi*v)
swiss <- cbind(x,y,z) # the data 150 by 3

# Color-code the points: from the center goes red, orange, green and blue
sel1 <- v < quantile(v,1/4)
sel2 <- (v >= quantile(v,1/4)) & (v <quantile(v,1/2))
sel3 <- (v >= quantile(v,1/2)) & (v <quantile(v,3/4))
col <- rep("blue",length(v))
col[sel1] <- "red"
col[sel2] <- "orange"
col[sel3] <- "green" # color vector
plot(u,v,col=col,xlim=range(c(u,v)),ylim=range(c(u,v)))


#xy <- cbind(u,v)
#for(j in 0:29) lines(xy[j*5+1:5,1], xy[j*5+1:5,2])
#for (j in 0:4) lines(xy[j+1+(0:29)*5,1],xy[j+1+(0:29)*5,2])
#plot(x,z,col=col)
#xy <- cbind(x,z)
#for(j in 0:29) lines(xy[j*5+1:5,1], xy[j*5+1:5,2])
#for (j in 0:4) lines(xy[j+1+(0:29)*5,1],xy[j+1+(0:29)*5,2])

#### ---- Use Boxcox function
# Generate the distance matrix "Do" and
#   a matrix containing neighborhood(K-NN) information "Inb"
k <- 6
Do <- dist(swiss)
Daux <- apply(Do,2,sort)[k+1,]
Inb <- ifelse(Do>Daux, 0, 1)
# Inb[i,] represents neighboring informaiton for i


# Local MDS (with random start)
conf1 <- boxcox(Do,  Inb, d=2, tau=1, col=col, niter=500)
# Using previous configuration as a start
conf2 <- boxcox(Do, Inb,X1=conf1$X, d=2, tau=.1,  col=col)

# Local MDS (with classical MDS start)
conf3 <- boxcox(Do,Inb,random.start=0, d=2, tau=10, col=col)

# Metric thresholding for contructing neighborhood
Inb <- ifelse(Do>.2, 0, 1)
conf4 <- boxcox(Do,  Inb, d=2, tau=1,col=col)

# Use a different stress function with lam=3
conf5 <-  boxcox(Do,  Inb,X1=conf4$X, d=2, lam=3, tau=0.01,col=col)
