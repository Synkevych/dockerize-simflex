FROM --platform=linux/amd64 ubuntu:18.04
LABEL maintainer Synkevych Roman "synkevych.roman@gmail.com"

# Install all dependencies
RUN apt-get update && apt-get install -y \
  vim software-properties-common \
  make gcc g++ zlib1g-dev python3 python3-pip \
  gfortran autoconf libtool automake bison cmake libnetcdff-dev \
  libeccodes0 libeccodes-data libeccodes-dev libeccodes-tools \
  curl wget time

RUN add-apt-repository 'deb http://security.ubuntu.com/ubuntu xenial-security main'\
  && apt-get update \
  && apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com \
  && apt-get install -y libjasper1 libjasper-dev

# Enable MPI
RUN apt-get -y install openmpi-bin libopenmpi-dev \
  && rm -rf /var/lib/apt/lists/*

#
# Download, modify and compile FLEXPART 10
#
COPY flexpart_v10.4/ flexpart_v10.4

RUN cd flexpart_v10.4/src \
  && cp makefile makefile_local \
  && sed -i '74 a INCPATH1 = /usr/include\nINCPATH2 = /usr/include\nLIBPATH1 = /usr/lib\n F90 = gfortran' makefile_local \
  && sed -i 's/LIBS = -lgrib_api_f90 -lgrib_api -lm -ljasper $(NCOPT)/LIBS = -leccodes_f90 -leccodes -lm -ljasper $(NCOPT)/' makefile_local \
  # && sed -i 's/nxmax=361,nymax=181,nuvzmax=138,nwzmax=138,nzmax=138/nxmax=721,nymax=361,nuvzmax=138,nwzmax=138,nzmax=138/g' par_mod.f90 \
  && make mpi ncf=yes -f makefile_local \
  && make clean
ENV PATH /flexpart_v10.4/src/:$PATH

#
# Copy input files and run test calculation
#
RUN mkdir /data/ && mkdir /data/calculations/

RUN cp -r /flexpart_v10.4/test/ /data/calculations/ \
  && cd /data/calculations/test/ \
  && cp /flexpart_v10.4/download_grib.py . \
  && cp /flexpart_v10.4/parser.py . \
  && cp /flexpart_v10.4/pathnames . \
  && cp -r /flexpart_v10.4/options .

#
# Compile SIMFLEX
#

COPY simflex_v1/ /simflex_v1

RUN cd /simflex_v1/src \
  && gfortran -c m_parse.for m_simflex.for \
  && gfortran *.f90 *.for -I/usr/include/ -L/usr/lib/ -lnetcdff -lnetcdf -o simflex

ENV PATH /simflex_v1/src/:$PATH

# Start calculations
# RUN python3 /data/calculations/test/parser.py
