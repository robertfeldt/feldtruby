# Code from Lisha Chen, in email 2013-07-04
#

#### ---- supporting functions for the main function
source("myfunctions.R")
                                       
#### ---- The main function for LMDS algorthim:
# Arguments:
# Do (nXn): dissimilarity(distance) matrix
# Inb (nXn): 1 for neighboring pairs; 0 for non-neighboring pairs; Inb[i,i] <- 1
# X1 (nXd): intial configuration, which is not specified by default (X1=NULL).
# random.start: Only matters when X1=NULL.
#               =1 random normal start; =0 Classical MDS configuration start.
# d: the dimension of the configuration
# lambda, mu, nu: tuning parameters for generalized LMDS family
#                 with default value for original LMDS function.
# tau:  tuning parameter for relative strength of repulsion force; one should start
#       with realtive large value like tau=1 and gradually lower it. Save the
#       configuration for larger tau as the intial start for the  next choice
#       of tau.
# niter: number of optimizing iterations, usually 500~1000 is enough.
# plot: =T to visualize of optimization procedure based on the first two PCs of
#       the configuration.
# color: a vector of length n to specify the color of the points

# -- output the configuration nXd and meta-criterion

boxcox <- function(Do,Inb,X1=NULL,random.start=1,d=3,lambda=1,mu=1,nu=0,tau=1,
                   niter=1000,plot=TRUE,color=NULL)
{
  n <- nrow(Do)
  #Do <- dist(X)
  #Daux <- apply(Do,2,sort)[k+1,]# choose the kth smallest distance expect 0.
  #Inb <- ifelse(Do>Daux, 0,1)
  k.v <-  apply(Inb, 1, sum)
  k <- (sum(k.v)-n)/n
  Inb.sum <- matrix(rep(k.v, n),ncol=n)
  Mka <- 0
  Inb1 <- pmax(Inb,t(Inb)) # expanding the neighbors for symmetry.
  Dnu <- ifelse(Inb1==1, Do^nu, 0)
  Dnulam <- ifelse(Inb1==1, Do^(nu+1/lambda), 0)
  diag(Dnu) <- 0
  diag(Dnulam) <- 0

  cc <- (sum(Inb1)-n)/n/n*median(Dnulam[Dnulam!=0])
  t <- tau*cc
  
  Grad <- matrix (0, nrow=n, ncol= d)
  if(is.null(X1) & random.start==1)
     X1 <- matrix(rnorm(n*d),nrow=n,ncol=d)
  if(is.null(X1) & random.start==0)
    {
      #J <- diag(rep(1,n)) - 1/n * rep(1,n) %*% t(rep(1,n))
      #B <- - 1/2 * J %*% Do %*% J
      #pc <- princomp(B)
      #X1 <- pc$loadings[,1:d]%*%diag(pc$sdev[1:d])
      cmd <- cmds(Do)
      X1 <- cmd$vec[,1:d]%*%diag(cmd$val[1:d])+
        norm(Do)/n/n*0.01*matrix(rnorm(n*d),nrow=n,ncol=d)
                                        # pc$loadings[,1:d]%*%diag(pc$sdev[1:d])

    }
  D1 <- dist(X1)
  X1 <- X1*norm(Do)/norm(D1)
  s1 <- Inf
  s0 <- 2
  stepsize <-0.1
  i <- 0

while ( stepsize > 1E-5 && i < niter)
  {
    if (s1 >= s0 && i>1)
     {
       stepsize<- 0.5*stepsize
       X1 <- X0 - stepsize*normgrad
     }
    else 
    {
      stepsize <- 1.05*stepsize
      X0 <- X1
      D1mu2 <- D1^(mu-2)
      diag(D1mu2) <- 0
      D1mulam2 <- D1^(mu+1/lambda-2)
      diag(D1mulam2) <- 0
      M <- Dnu*D1mulam2-D1mu2*(Dnulam+t*(!Inb1))
   #   m <- rep(1,n)%*%M
   #   Grad <- rep(m,rep(d,n))*X0-X0%*%M
      E <- matrix(rep(1,n*d),n,d)
      Grad <- X0*(M%*%E)-M%*%X0
      normgrad <- (norm(X0)/norm(Grad))*Grad
      X1 <- X0 - stepsize*normgrad
     }
    i <- i+1
    s0 <- s1
    D1 <- dist(X1)
    D1mulam <- D1^(mu+1/lambda)
    diag(D1mulam) <- 0
    D1mu <- D1^mu
    diag(D1mu) <- 0
    if(mu+1/lambda==0)
      {
        diag(D1)<-1
       s1 <- sum(Dnu*log(D1))-sum((D1mu-1)*Dnulam)/mu -t*sum((D1mu-1)*(1-Inb1))/mu
      }

    if(mu==0)
      {
       diag(D1)<-1
       s1 <- sum(Dnu*(D1mulam-1))/(mu+1/lambda) -sum(log(D1)*Dnulam)-t*sum(log(D1)*(1-Inb1))
      }

    if(mu!=0&(mu+1/lambda)!=0)
    s1 <- sum(Dnu*(D1mulam-1))/(mu+1/lambda)-sum((D1mu-1)*Dnulam)/mu-t*sum((D1mu-1)*(1-Inb1))/mu

    ## Printing and Plotting
    if( (i+1)%% 100==0)
      {
#        print (paste("niter=",i+1," stress=",s1,sep=""))
        D1.rk <- apply(D1, 1, rank)
        D1.Inb <- ifelse(D1.rk>Inb.sum, 0, 1)
        Nk <- (apply(D1.Inb*Inb, 1, sum)-1)/(k.v-1)
        Mka <- sum(Nk)/n - k/n
        print (paste("niter=",i+1," stress=",round(s1,5),
                     " Mk_adj=", round(Mka,5), sep=""))
      }
    if(plot)
      {
        conf.pc <- prcomp(X1)$x[,1:2]
        if(!is.null(color))
          {
#            if(d==2)
              plot(conf.pc, main=paste("Mk_adj=",round(Mka,5)), xlim=range(conf.pc),
                   ylim=range(conf.pc), col=color,pch=16)
#            else
#              scatterplot3d(conf.pc ,main=paste("Mk_adj=",round(Mka,5)),
#                            xlim=range(conf.pc),ylim=range(conf.pc), col=color)
          }
        else
          {
#            if(d==2)
              plot(conf.pc, main=paste("Mk_adj=",round(Mka,5)),xlim=range(conf.pc),
                   ylim=range(conf.pc),pch=16)
#            else
#              scatterplot3d(conf.pc ,main=paste("Mk_adj=",round(Mka,5)),
#                            xlim=range(conf.pc),ylim=range(conf.pc))
          }
            
      }
  }
  result <- list()
  result$X <- X1
  result$Mka <- Mka
  result$pc1 <- conf.pc[,1]
  result$pc2 <- conf.pc[,2]
  return(result)
}
