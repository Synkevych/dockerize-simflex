# dockerize-simflex

Flexpart conternization with simflex

## How to use

1. Build the image locally in the `dockerize-simflex` folder:
`docker build -t simflex:v1 .`
2. Run the container using created image
`docker run -it simflex:v1`
3. Stop the container
4. Delete container, all data will be lost
5. Delete image
6. Increase performance by adding more cores and memory

## Changes in Flexpart

1. File <par_mod.f90>

```
141 - integer,parameter :: nxmax=361,nymax=181,nuvzmax=138,nwzmax=138,nzmax=138
141 + integer,parameter :: nxmax=721,nymax=361,nuvzmax=138,nwzmax=138,nzmax=138 ! 0.5 degree 138 level

198 - integer,parameter :: maxreceptor=20 ! maximum number of receptor points
198 + integer,parameter :: maxreceptor=200

207 - integer,parameter :: maxpart=100000 ! Maximum number of particles
207 + integer,parameter :: maxpart=7500000

208 -  integer,parameter :: maxspec=1 ! Maximum number of chemical species per release
208 + integer,parameter :: maxspec=4
```

2. File <makefile> in line 75 added the following:

```
INCPATH1 = /usr/include
INCPATH2 = /usr/include
LIBPATH1 = /usr/lib
 F90 = gfortran
```

## parallelizing using Message Passing Interface (MPI)

The model scales well up to using 256 processors, with a parallel efficiency greater than 75 % for up to 64 processes on multiple nodes in runs with very large numbers of particles. The deviation from 100 % efficiency is almost entirely due to the remaining nonparallelized parts of the code, suggesting large potential for further speedup. A new turbulence scheme for the convective boundary layer has been developed that considers the skewness in the vertical velocity distribution (updrafts and downdrafts) and vertical gradients in air density. FLEXPART is the only model available considering both effects, making it highly accurate for small-scale applications, e.g., to quantify dispersion in the vicinity of a point source.

Open Multi-Processing ([OpenMP](http://www.openmp.org/))

### Performance test

|Type| Flexpart version|Input dates start/end|Loutstep|Parts|Calc Times|
|-|-|-|-|-|-|
|1 Server|Serial*|20200418/21 0/0|360|10000|5280s or 1h23m|
|1 Server|Serial(-j 8)*|20200418/21 0/0|360|10000|5246s|
|1 Server|MPI(-j 12)**|20200418/21 0/0|360|10000|7m46.718s|
|1 Server|MPI(-j 8)**|20200418/21 0/0|360|10000|7m47.168s|
|1 Server|MPI(-j 4)**|20200418/21 0/0|360|10000|7m46.115s|
|2 Docker container|Serial|20200418/21 0/0|360|10000|0s|
|2 Docker container|MPI|20200418/21 0/0|360|10000|0s|
|2 Docker container|MPI 4 core|20200418/19 0/13|3600|10000|1h35m28s|

'*' - single core (didn't use -j parameter)
'**' - multiply core using open-mpi

> make [-j] mpi ncf=yes - Compile parallel FLEXPART
> make [-j] serial ncf=yes - Compile serial FLEXPART

## Resources

<https://gmd.copernicus.org/articles/12/4955/2019/>  
[Flexpart v10.4 instalation process](https://www.jianshu.com/p/6bc7cee6c9bf)  
[FLEXPART installation notes](http://paisheng.me/2018/08/10/FLEXPART_INSTALLATION_NOTE)
