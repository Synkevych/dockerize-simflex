# dockerize-simflex

Flexpart conternization with simflex.  
To make Flexpart work you should install all required libraries and provide required inputs. This project is created to make it easy all steps explained previously .

## Flexpart

FLEXPART (“FLEXible PARTicle dispersion model”) is a Lagrangian transport and dispersion model suitable for the simulation of a large range of atmospheric transport processes. Apart from transport and turbulent diffusion, it is able to simulate dry and wet deposition, decay, linear chemistry; it can be used in forward or backward mode, with defined sources or in a domain-filling setting. It can be used from local to global scale.

## How parsing works

#### Creating COMMAND file for flexpart inputs

![Command file](/docs/command.png)

#### Creating OUTGRID file for flexpart inputs

![Outgrid file](/docs/outgrid.png)

#### Creating simflexinp.nml for simflex inputs

![Simflexinp.nml file](/docs/simflexinp.png)

#### Creating RELEASES file for flexpart on each iteration

![Releases file](/docs/releases.png)

#### Creating or updating table_srs_paths.txt file for simlex on each iteration

![Table_srs_paths file](/docs/table_srs_paths.png)

## How to use

1. Build the image locally in the `dockerize-simflex` folder:
`docker build -t simflex:v1 .`
2. Run the container using created image
`docker run -it simflex:v1`
3. Stop the container
4. Delete container, all data will be lost
5. Delete image
6. Increase performance by adding more cores and memory

## Changes from the origin

### Changes in Flexpart

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

## Performance test

- Simulation direction – backward
- Species №18 or Ru-106
- Input IBDATE 20200418, IBTIME 000000, IEDATE 20200421, IETIME 130010 (other paramethers in [test](/flexpart_v10.4/test/) folder)

> Serial - single core, MPI – multiply core using open-mpi.

|Where|Type|Model name|CPU(s)|Loutstep|Parts|Calc Times|
|-|-|:-:|:-:|:-:|:-:|:-:|
|Server|MPI|Intel Xeon Gold 6240 2.6GHz(85)|72|3600|10000|3977s or 66m|
|Server|Serial||||10000|5280s or 83m|
|Server|Serial|||360|10000|5246s|
|Server|MPI|||360|10000|7m46.718s|
|Server|MPI|||360|10000|7m47.168s|
|Server|MPI|||360|10000|7m46.115s|
|Docker|Serial|Intel Core i5-8250U 1.6GHs(142)|4|3600|10000|16200s or 270m|
|Docker|MPI|||3600|10000|1h35m28s|
|Docker|MPI|Apple M1(ARM64)|8|3600|10000|43200s or 720m|


> make [-j] mpi ncf=yes - Compile parallel FLEXPART. 
> make [-j] serial ncf=yes - Compile serial FLEXPART

## Resources

<https://gmd.copernicus.org/articles/12/4955/2019/>  
[Flexpart v10.4 instalation process](https://www.jianshu.com/p/6bc7cee6c9bf)  
[FLEXPART installation notes](http://paisheng.me/2018/08/10/FLEXPART_INSTALLATION_NOTE)
