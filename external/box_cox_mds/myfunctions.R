# Generate sprial data: 100 points, 3 dimension
ang <- sqrt(seq(1.5,4,length=25))*3*pi
spiral.dat <- cbind(rep(ang^2*cos(ang),4),
               rep(ang^2*sin(ang),4),
               100*rep(1:4,rep(25,4)))


#### Calculate the distance matrix of X: n by p ####
dist <- function(X)
  {
    X2 <- apply (X, 1, function(z)sum(z^2))
    dist2 <- outer(X2, X2, "+")- 2*X%*%t(X)
    dist2 <- ifelse(dist2<0,0,dist2)
    return (sqrt(dist2))
   }

norm <- function(x) sqrt(sum(x^2))

######### lle(X,k,d) ########
# X -- original data: n by p
# k -- number of neibouring points
# d -- desired dimension
lle <- function(X, k, d)
  {

    n <- nrow(X)
    sigmasqr<-.55
    XtX <- X%*%t(X)
    x2 <- apply(X,1,function(z)sum(z^2))
    D2 <- outer(x2,x2,"+") - 2*XtX

    W<-matrix(0,n,n)
    for(i in 1:n)
      {
        sel<-rank(D2[i,])<k+2 & rank(D2[i,])>1
        ll<-sum(sel==TRUE)
        e<-rep(1,ll)
        D<-diag(e)
        # solution of W suggested by paper
        C<-solve(XtX[sel,sel]+sigmasqr*D)
        alpha<-1-t(e)%*%C%*%X[sel,]%*%X[i,]
        Beta<-t(e)%*%C%*%e
        W[i,sel]<-C%*%(X[sel,]%*%X[i,]+alpha/Beta*e)
      }
    M <- diag(n) - W - t(W) + t(W) %*% W
    # LLE eigen decomposition:
    M.eig <- eigen(M)
    # IMPORTANT: last eigenvector should be constant
    # the reduced dimensions should be the last n-d to n-1 eigenvectors  
    return(M.eig$vec[,(n-1):(n-d)])
}



## This function is to prepare the graph to calculate shortest path.
# X is n by p;
# k is the number of neighbouring points;
# filename specify the directory to save the graph
geod <- function(X,k=NULL,r=NULL,filename=NULL)
  {
    Do <- dist(X)
    # choose the kth shortest distance, expect diagonal zeros
    if(!is.null(k))
      Daux <- apply(Do,2,sort)[k+1,]
    if(!is.null(r))
      Daux <- rep(r,nrow(X))
    face.r <- row(Do)[Do<=Daux]
    face.c <- col(Do)[Do<=Daux]
    sel <- face.r != face.c
    face.graph <- cbind(face.r, face.c, Do[Do<=Daux])[sel,]
    if(!is.null(filename))
    write(t(face.graph), file=filename,ncol=ncol(face.graph))
    return(face.graph)
  }

# CMDS:

#Do <- dist(cbind(x,y,z))
cmds <- function(Do)
  {
    n <- nrow(Do)
    J <- diag(rep(1,n)) - 1/n * rep(1,n) %*% t(rep(1,n))
    B <- - 1/2 * J %*% (Do^2) %*% J
    pc <- eigen(B)
#    pc <- princomp(covmat=B)
    return(pc)
  }

#plot(pc$sdev)
#plot(pc$scale)
#plot(pc$loadings[,1:2]%*%diag(pc$sdev[1:2]))

# Caculate Local LC criterion
overlap.v <- function(X,Inb,myk)
  {
    myDo <- dist(X)
    myDaux <- apply(myDo,2,sort)[myk+1,]# choose the kth largest distance
    myInb <- ifelse(myDo>myDaux, 0,1)
    overlap.m <- Inb*myInb
    myoverlap.v <- apply(overlap.m, 1, sum)-1
    return(myoverlap.v)
  }

# Updated version for LC criterion
loc.meta <- function(Inb,conf)
  {
    n <- nrow(Inb)
    k.v <- apply(Inb,1,sum)
    k.v.mat <- matrix(rep(k.v,n),ncol=n,byrow=T)
#    k.v.mat <- matrix(rep(k.v,n),ncol=n)
    D1 <- dist(conf)
    D1.rk <- apply(D1, 2, rank)
#    D1.rk <- apply(D1, 1, rank) # row-wise ranking and column-wise fill in.
    D1.Inb <- ifelse(D1.rk>k.v.mat, 0,1 )
#    D1.Inb <- ifelse(D1.rk<k.v.mat+1, 1, 0)
    Nk <- (apply(D1.Inb*Inb, 2, sum)-1)/(k.v-1)
    Mka <- mean(Nk)-(sum(Inb)-n)/n/n
    result <- list()
    result$Nk <- Nk
    result$Mka <- Mka
    return(result)
  }

# From loc.meta to Mk_adj
#  mean(Nk)-(sum(Inb)-n)/n/n
