FROM --platform=linux/amd64 ubuntu:18.04
LABEL maintainer Synkevych Roman "synkevych.roman@gmail.com"

# Install all dependencies
RUN apt-get update && apt-get install -y \
  language-pack-en openssh-server vim software-properties-common \
  build-essential make gcc g++ zlib1g-dev git python3 python3-dev python3-pip \
  gfortran autoconf libtool automake flex bison cmake git-core \
  libeccodes0 libeccodes-data libeccodes-dev libeccodes-tools \
  libnetcdff-dev unzip curl wget

RUN add-apt-repository 'deb http://security.ubuntu.com/ubuntu xenial-security main'\
  && apt-get update \
  && apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com \
  && apt-get install -y libjasper1 libjasper-dev

# Enable MPI
RUN apt-get -y install openmpi-bin libopenmpi-dev

#
# Download, modify and compile FLEXPART 10
#
RUN mkdir flex_src && cd flex_src \
  && wget https://www.flexpart.eu/downloads/66 \
  && tar -xvf 66 \
  && rm 66 \
  && cd flexpart_v10.4_3d7eebf/src \
  && cp makefile makefile_local \
  && sed -i '74 a INCPATH1 = /usr/include\nINCPATH2 = /usr/include\nLIBPATH1 = /usr/lib\n F90 = gfortran' makefile_local \
  && sed -i 's/LIBS = -lgrib_api_f90 -lgrib_api -lm -ljasper $(NCOPT)/LIBS = -leccodes_f90 -leccodes -lm -ljasper $(NCOPT)/' makefile_local \
  && sed -i 's/nxmax=361,nymax=181,nuvzmax=138,nwzmax=138,nzmax=138/nxmax=721,nymax=361,nuvzmax=138,nwzmax=138,nzmax=138/g' par_mod.f90 \
  && make mpi ncf=yes -f makefile_local
ENV PATH /flex_src/flexpart_v10.4_3d7eebf/src/:$PATH

#
# Compile SIMFLEX
#
# COPY simflex /simflex
#   && wget http://env.com.ua/~sunkevu4/simflex.tar.gz \
#   && tar -xvf simflex.tar.gz \
#   && rm simflex.tar.gz
#   && ./cmpl_simflex
#
