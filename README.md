# dockerize-simflex

- [dockerize-simflex](#dockerize-simflex)
  - [Flexpart](#flexpart)
  - [How parsing works](#how-parsing-works)
      - [Creating COMMAND file for flexpart inputs](#creating-command-file-for-flexpart-inputs)
      - [Creating OUTGRID file for flexpart inputs](#creating-outgrid-file-for-flexpart-inputs)
      - [Creating simflexinp.nml and measurem.csv for simflex inputs](#creating-simflexinpnml-and-measuremcsv-for-simflex-inputs)
      - [Creating RELEASES file for flexpart on each iteration](#creating-releases-file-for-flexpart-on-each-iteration)
      - [Creating or updating table_srs_paths.txt file for simflex on each iteration](#creating-or-updating-table_srs_pathstxt-file-for-simflex-on-each-iteration)
  - [How to use](#how-to-use)
  - [Changes from the origin](#changes-from-the-origin)
    - [Changes in Flexpart](#changes-in-flexpart)
  - [parallelizing using Message Passing Interface (MPI)](#parallelizing-using-message-passing-interface-mpi)
  - [Performance test](#performance-test)
  - [Resources](#resources)

Flexpart conternization with simflex.  
To make Flexpart work you should install all required libraries and provide required inputs. This project is created to make it easy and isolated from your work environment.

## Flexpart

FLEXPART (“FLEXible PARTicle dispersion model”) is a Lagrangian transport and dispersion model suitable for the simulation of a large range of atmospheric transport processes. Apart from transport and turbulent diffusion, it is able to simulate dry and wet deposition, decay, linear chemistry; it can be used in forward or backward mode, with defined sources or in a domain-filling setting. It can be used from local to global scale.

## How parsing works

#### Creating COMMAND file for flexpart inputs

![Command file](/docs/command.png)

#### Creating OUTGRID file for flexpart inputs

![Outgrid file](/docs/outgrid.png)

#### Creating simflexinp.nml and measurem.csv for simflex inputs

![Simflexinp.nml file](/docs/simflexinp.png)

#### Creating RELEASES file for flexpart on each iteration

![Releases file](/docs/releases.png)

#### Creating or updating table_srs_paths.txt file for simflex on each iteration

![Table_srs_paths file](/docs/table_srs_paths.png)

## How to use

1. Build the image locally in the `dockerize-simflex` folder:  
`docker build -t simflex:v1 .`  
**1.1.** Copy grib file to docker container if you have it  
`docker cp /path/grib.tar.gz container_id:/data/grib_data/`  
**1.2**. If you want to interact with image without calculation use(data will be lost after you disconnect):  
`docker run --rm -it --entrypoint bash simflex:v1`
2. Run the calculations by running container using created image:  
`docker run --name simflex simflex:v1`
2.1 Connect to the container without calculations(for example test purpose)
`docker run -it --name simflex --entrypoint /bin/bash simflex:v1`
3. For connect to the container use:  
`docker exec -it simflex:v1 /bin/bash`
4. After completed calculation container will be stopped. Folder hierarchy will be:
![files in test folder](/docs/test_files.png)
4.1. To copy simflex result from simflex_output folder use:  
`docker cp simflex:/data/calculations/test/simflex_output .`  
4.2. To copy simflex input files use:  
`docker cp simflex:/data/calculations/test/simflex_input .`  
4.3. If calculation didn't complete successful use logs file to understand the problem:
`docker logs -t simflex`  
OR copy local log-file from container  
`docker cp simflex:/data/calculations/test/parsing.log . && cat parsing.log`  
4.4. All calculations also available on your machine(tested on Linux) because we copy all calculation to volume, but first you need to get volumes ID:  
`docker container inspect simflex | grep Source | awk -F\" '{print $4}'`
Than use it value as a path to your folder with all information:  
![volumes name and folders](/docs/volume_location.png)
5. Deleting  
5.1. Delete container, all data will be lost:  
`docker rm simflex`  
5.2. Delete image:  
`docker image rm simflex:v1`  
5.3. Delete all:  
`docker image prune -f`  
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
208 + integer,parameter :: maxspec=6
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

> make [-j] mpi ncf=yes - Compile parallel FLEXPART_MPI  
> make [-j] serial ncf=yes - Compile serial FLEXPART

## Performance test

- Simulation direction – backward
- Species №18 or Ru-106
- Input IBDATE 20200418, IBTIME 000000, IEDATE 20200421, IETIME 130010 (other paramethers in [test](/flexpart_v10.4/test/) folder)
- Time does not include the time of downloading **grib_data** so calculation time would be increased

|Where|System|Type|Model name|CPU(s)|RAM|Loutstep|Parts|Calc Times|
|-|-|-|:-:|:-:|:-:|:-:|:-:|:-|
|Docker|macOS|MPI|Apple M1(ARM64)|8|8Gb|3600|10000|1d, 18:26:27.673187|
|Docker|Ubuntu 18.04.4|Serial|Intel Xeon CPU E5335 2.0GHs(15)|8|15.66GiB|3600|10000|17:40:18.740042|
|Docker|Windows 10|Serial|Intel Core i5-8250U 1.6GHs(142)|8|16Gb|3600|10000|10:53:27.204476|
|Docker|Ubuntu 18.04.4|MPI|Intel Xeon CPU E5335 2.0GHs(15)|8|15.66GiB|3600|10000|3:44:23.769362|
|Docker|Windows 10|MPI|Intel Core i5-8250U 1.6GHs(142)|4|10Gb|3600|10000|1:47:01.369211|
|Docker|Windows 10|MPI|Intel Core i5-8250U 1.6GHs(142)|8|16Gb|3600|10000|1:45:34.842323|
|Server|Ubuntu 18.04|MPI|Intel Xeon Gold 6240 2.6GHz(85)|72|187G|3600|10000|1:02:03.195422|

> Serial - single core, MPI – multiply core using open-mpi  
> CPUs value show all cores virtual and real

## Resources

<https://gmd.copernicus.org/articles/12/4955/2019/>  
[Flexpart v10.4 instalation process](https://www.jianshu.com/p/6bc7cee6c9bf)  
[FLEXPART installation notes](http://paisheng.me/2018/08/10/FLEXPART_INSTALLATION_NOTE)
