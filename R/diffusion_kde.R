# Gaussian KDE downloaded from 
#   http://www-etud.iro.umontreal.ca/~botev/kde.R
# on February 9th 2013. 
# Our changes:
#   - Renamed function from kde to diffusion.kde
#   - Return an object instead of a matrix
#   - Added the sum of the densities
#   - Added the mesh interval
#   - Added the probabilities for each interval
# No license was specified on this piece of code. For questions about it please contact
# Prof. Botev on the email: botev@maths.uq.edu.au
diffusion.kde <- function(data,n,MIN,MAX){
#       State-of-the-art gaussian kernel density estimator for one-dimensional data;
#       The estimator does not use the commonly employed 'gaussian rule of thumb'.
#       As a result it outperforms many plug-in methods on multimodal densities 
#       with widely separated modes (see example).
# INPUTS:
#     data    - a vector of data from which the density estimate is constructed;
#          n  - the number of mesh points used in the uniform discretization of the
#               interval [MIN, MAX]; n has to be a power of two; if n is not a power of two, then
#               n is rounded up to the next power of two; the default value of n is n=2^12;
#   MIN, MAX  - defines the interval [MIN,MAX] on which the density estimate is constructed;
#               the default values of MIN and MAX are:
#               MIN=min(data)-Range/10 and MAX=max(data)+Range/10, where Range=max(data)-min(data);
# OUTPUT: 
#       matrix 'out' of with two rows of length 'n', where out[2,] 
#       are the density values on the mesh out[1,]; 
# EXAMPLE: 
##Save this file in your directory as kde.R and copy and paste the commands:  
# rm(list=ls())
# source(file='kde.r')
# data=c(rnorm(10^3),rnorm(10^3)*2+30);
# d=kde(data)
# plot(d[1,],d[2,],type='l',xlab='x',ylab='density f(x)')

# REFERENCE: 
# Z. I. Botev, J. F. Grotowski and D. P. Kroese
# "Kernel Density Estimation Via Diffusion"
# Annals of Statistics, 2010, Volume 38, Number 5, Pages 2916-2957
# for questions email: botev@maths.uq.edu.au

nargin=length(as.list(match.call()))-1;
if (nargin<2) n=2^14
n=2^ceiling(log2(n)); # round up n to the next power of 2;
if (nargin<4) 
{# define the default  interval [MIN,MAX]
minimum=min(data); maximum=max(data);
Range=maximum-minimum;
MIN=minimum-Range/10; MAX=maximum+Range/10;
}
# set up the grid over which the density estimate is computed;
R=MAX-MIN; dx=R/n; xmesh=MIN+seq(0,R,dx); N=length(data); 
# if data has repeated observations use the N below
# N=length(as.numeric(names(table(data))));
# bin the data uniformly using the grid defined above;
w=hist(data,xmesh,plot=FALSE);initial_data=(w$counts)/N;
initial_data=initial_data/sum(initial_data);

dct1d <- function(data){
# computes the discrete cosine transform of the column vector data
n= length(data);
# Compute weights to multiply DFT coefficients
weight = c(1,2*exp(-1i*(1:(n-1))*pi/(2*n)));
# Re-order the elements of the columns of x
data = c(data[seq(1,n-1,2)], data[seq(n,2,-2)]);
# Multiply FFT by weights:
data= Re(weight* fft(data));
data}

a=dct1d(initial_data); # discrete cosine transform of initial data
# now compute the optimal bandwidth^2 using the referenced method
I=(1:(n-1))^2; a2=(a[2:n]/2)^2;
# use  fzero to solve the equation t=zeta*gamma^[5](t)

fixed_point <-  function(t,N,I,a2){
# this implements the function t-zeta*gamma^[l](t)
l=7;
f=2*(pi^(2*l))*sum((I^l)*a2*exp(-I*(pi^2)*t));
for (s in (l-1):2){

    K0=prod(seq(1,2*s-1,2))/sqrt(2*pi);  const=(1+(1/2)^(s+1/2))/3;
    time=(2*const*K0/N/f)^(2/(3+2*s));
    f=2*pi^(2*s)*sum(I^s*a2*exp(-I*pi^2*time));
}
out=t-(2*N*sqrt(pi)*f)^(-2/5);
}

t_star=tryCatch(uniroot(fixed_point,c(0,.1),N=N,I=I,a2=a2,tol=10^(-14))$root,error=function(e) .28*N^(-2/5));
# smooth the discrete cosine transform of initial data using t_star
a_t=a*exp(-(0:(n-1))^2*pi^2*t_star/2);
# now apply the inverse discrete cosine transform

idct1d <-  function(data){
# computes the inverse discrete cosine transform
n=length(data);
# Compute weights
weights = n*exp(1i*(0:(n-1))*pi/(2*n));
# Compute x tilde using equation (5.93) in Jain
data = Re(fft(weights*data,inverse=TRUE))/n;
# Re-order elements of each column according to equations (5.93) and
# (5.94) in Jain
out = rep(0,n);
out[seq(1,n,2)] = data[1:(n/2)];
out[seq(2,n,2)] = data[n:(n/2+1)];
out;
}

density=idct1d(a_t)/R;
# take the rescaling of the data into account
bandwidth=sqrt(t_star)*R;
xmesh=seq(MIN,MAX,R/(n-1));
# out=matrix(c(xmesh,density),nrow=2,byrow=TRUE);
posd = density + abs(min(0.0, min(density))); # Ensure least density is 0.0 before calcing probabilities
list(probabilities = (posd / sum(posd)), densities = density, mesh = xmesh, 
  sum_density = sum(density), mesh_interval = (R/(n-1)), min = MIN, max = MAX)
}