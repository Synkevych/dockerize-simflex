# dockerize-simflex

- [dockerize-simflex](#dockerize-simflex)
  - [Flexpart](#flexpart)
  - [How to test that docker image work](#how-to-test-that-docker-image-work)
  - [How parsing works](#how-parsing-works)
  - [How to use](#how-to-use)
  - [Changes from the origin](#changes-from-the-origin)
    - [Changes in Flexpart](#changes-in-flexpart)
  - [Parallelizing using Message Passing Interface (MPI)](#parallelizing-using-message-passing-interface-mpi)
  - [Performance test](#performance-test)
    - [Debugging](#debugging)
  - [Resources](#resources)

Flexpart containerization with simflex.
SIMFLEX – Source Inversion Module-FLEXPART.  
To make Flexpart work you should install all required libraries and provide the required inputs. This project is created to make it easy and isolated from your work environment.

## Flexpart

FLEXPART (“FLEXible PARTicle dispersion model”) is a Lagrangian transport and dispersion model suitable for simulating a large range of atmospheric transport processes. Apart from transport and turbulent diffusion, it is able to simulate dry and wet deposition, decay, linear chemistry; it can be used in forward or backward mode, with defined sources, or in a domain-filling setting. It can be used from local to global scale.

## How to test that docker image work

Tested for compatibility with 3 cores; if more than 3 cores are provided, an error will occur after the first calculation. In OpenStack, you can utilize `$(nproc)` to utilize all available cores.

```sh
# Assuming you are in the root folder of the git repository
cp -rf flexpart_v10.4/test 1;
docker build -t simflex:beta -f Dockerfile .;
cd 1;
mkdir results;
docker run --privileged -d -v "$PWD":/data/ -v "$PWD/results/":/series/ --name calculation_$(basename "$(pwd)") simflex:beta
```

## How parsing works

1. Creating COMMAND file for Flexpart inputs

![Command file](/docs/command.png)

2. Creating OUTGRID file for flexpart inputs

![Outgrid file](/docs/outgrid.png)

3. Creating simflexinp.nml and measurem.csv for simflex inputs

![Simflexinp.nml file](/docs/simflexinp.png)

4. Creating RELEASES file for flexpart on each iteration

![Releases file](/docs/releases.png)

5. Creating or updating table_srs_paths.txt file for simflex on each iteration

![Table_srs_paths file](/docs/table_srs_paths.png)

## How to use

1. Build the image locally in the `dockerize-simflex` folder: `docker build -t simflex:v1 .`  
2. Prepare input data for the calculation. Create a folder for example `1` and `input` inside it, then put there two files: `measurements.txt` and `options.xml`, also create folder `series` for Flexpart output in the same path that `1` has.  
3. Run the calculations by running the container using created image and input data, to run container on all available CPUs use `--privileged` argument: `docker run --privileged -d -v --name=simflex "$PWD":/data/ simflex:v1`  
4. To connect to the running container use: `docker exec -it simflex /bin/bash`  
5. After calculations simflex output files will be located in `data/output/Nuclide-name`, these folders are generated by simflex.  
6. Delete container, all data inside the container will be lost: `docker rm --volumes simflex`  

Description of the processes inside the container:
As input data used two files: `measurements.txt` and `options.xml` which are located in the `/data/input/` folder. The main script `run.sh` will parse these files and create all required files for Flexpart and Simflex. After that, the calculation will start. The output data will be located in the `/data/output/`  and `/series/series_id/` folders. After the calculation is complete, the container will be stopped.
All process logs will be located in the `/data/calculations.log` file or you can use `docker logs -t container_id` command.

<details>
<summary><b>Other useful commands:</b></summary>
<br>

Copy grib file to the docker container if you have them locally: `docker cp /path/grib.tar.gz container_id:/data/grib_data/`  
Interact with an image without calculation (all changes and data will be lost after you disconnect): `docker run --rm -it --entrypoint bash simflex:v1`  
Connect to the container without calculations(for example test purpose): `docker run -it --name simflex --entrypoint /bin/bash simflex:v1`
Copy files/folders from the container to current local locations: `docker cp simflex:/data/calculation .`  
If the calculation didn't complete successfully use the logs file to understand the problem: `docker logs -t simflex`  
All calculations are also available on your machine(tested on Linux) because we copy all calculations to volume, but first, you need to get volumes ID: `docker container inspect simflex | grep Source | awk -F\" '{print $4}'`
Simflex output files inside the container will be located in the `/data/output/Nuclide-name/`, use this value as a path to your folder with all information:  
![volumes name and folders](/docs/volume_location.png)
Delete image: `docker image rm simflex:v1`  
Delete all images that are not used: `docker image prune -f`  
Increase performance by adding more cores and memory  
`docker inspect 345cb4176398 | grep Source` get the path where the input data is located  
`head ../input/measurements.txt | grep '^99;1;8' && head ../../4/input/measurements.txt | grep '^4;1;8'` - different between two files  
`docker rm $(docker ps -q --filter "status=exited")` remove all exited containers
</details>

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

## Parallelizing using Message Passing Interface (MPI)

The model scales well up to using 256 processors, with a parallel efficiency greater than 75 % for up to 64 processes on multiple nodes in runs with very large numbers of particles. The deviation from 100 % efficiency is almost entirely due to the remaining nonparallelized parts of the code, suggesting a large potential for further speedup. A new turbulence scheme for the convective boundary layer has been developed that considers the skewness in the vertical velocity distribution (updrafts and downdrafts) and vertical gradients in air density. FLEXPART is the only model available considering both effects, making it highly accurate for small-scale applications, e.g., to quantify dispersion in the vicinity of a point source.

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
> CPUs value shows all cores virtual and real

### Debugging

- [x] Change the user to root if you want to install/change something
- [ ] Use command `docker run -d -it --entrypoint="/bin/bash" -v "$PWD":/data/ -v /home/flexpart/series/:/series/ simflex:final` to connect to the container without calculations(for example test purpose)
- [ ] And then use `docker exec -it simflex /bin/bash` to connect to the running container

Command `docker inspect -f '{{.State.ExitCode}}' container_name`.
If the container after calculation has *ExitCode 0* then everything is ok, if *ExitCode 1* then something went wrong while calculation, container should be restarted, if *ExitCode 2* then something went wrong with user files and user should be informed about it.

## Resources

<https://gmd.copernicus.org/articles/12/4955/2019/>  
[Flexpart v10.4 instalation process](https://www.jianshu.com/p/6bc7cee6c9bf)  
[FLEXPART installation notes](http://paisheng.me/2018/08/10/FLEXPART_INSTALLATION_NOTE)
