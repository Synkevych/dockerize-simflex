FROM --platform=linux/amd64 ubuntu:18.04
LABEL maintainer Synkevych Roman "synkevych.roman@gmail.com"

# Install all dependencies
RUN apt-get update && apt-get install -y \
  language-pack-en openssh-server vim software-properties-common \
  build-essential make gcc g++ zlib1g-dev git python3 python3-dev python3-pip \
  gfortran autoconf libtool automake flex bison cmake git-core \
  libeccodes0 libeccodes-data libeccodes-dev libeccodes-tools \
  libnetcdff-dev unzip curl wget time

RUN add-apt-repository 'deb http://security.ubuntu.com/ubuntu xenial-security main'\
  && apt-get update \
  && apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com \
  && apt-get install -y libjasper1 libjasper-dev

# Enable MPI
RUN apt-get -y install openmpi-bin libopenmpi-dev

#
# Download, modify and compile FLEXPART 10
#
COPY flexpart_v10.4/ flexpart_v10.4
RUN cd flexpart_v10.4/src \
  && cp makefile makefile_local \
  && sed -i '74 a INCPATH1 = /usr/include\nINCPATH2 = /usr/include\nLIBPATH1 = /usr/lib\n F90 = gfortran' makefile_local \
  && sed -i 's/LIBS = -lgrib_api_f90 -lgrib_api -lm -ljasper $(NCOPT)/LIBS = -leccodes_f90 -leccodes -lm -ljasper $(NCOPT)/' makefile_local \
  && make mpi ncf=yes -f makefile_local
ENV PATH flexpart_v10.4/src/:$PATH

#
# Copy input files and run calculation
#
RUN mkdir data/calculations/

RUN cd flexpart_v10.4/test \
  && cp ../download_grib.py . \
  && cp ../parser.py . \
  && cp ../pathnames . \
  && cp -r ../options . \
  && ln -s /flexpart_v10.4/src/FLEXPART_MPI . \
  && python3 parser.py

#
# Compile SIMFLEX
#
COPY simflex_v1/ /simflex_v1
RUN cd /simflex_v1/src \
  && ./cmpl_simflex \


  && cd flexpart_v10.4/test\simflex \
  && ln -s /simflex_v1/src/simflex . \
  && ./simflex
# ENV PATH /simflex_v1/src/:$PATH
