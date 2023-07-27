FROM --platform=linux/amd64 ubuntu:18.04
LABEL maintainer Synkevych Roman "synkevych.roman@gmail.com"

# Install all dependencies
RUN apt-get update && apt-get install -y \
  openssh-server software-properties-common build-essential \
  make gcc g++ zlib1g-dev python3 python3-pip \
  gfortran autoconf libtool automake bison libssl-dev\
  libeccodes0 libeccodes-dev libnetcdff-dev vim

RUN add-apt-repository 'deb http://security.ubuntu.com/ubuntu xenial-security main'\
  && apt-get update \
  && apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com \
  && apt-get install -y libjasper1 libjasper-dev

# Enable MPI
RUN apt-get -y install openmpi-bin libopenmpi-dev \
  && rm -rf /var/lib/apt/lists/*
# Set the environment variables for the C and Fortran compilers
ENV CC=gcc
ENV FC=gfortran

# Install CMake 3.20.0
RUN wget https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0.tar.gz\
  && tar -zxvf cmake-3.20.0.tar.gz \
  && cd cmake-3.20.0 \
  && ./bootstrap \
  && make \
  && make install \
  && cd .. \
  && rm -rf cmake-3.20.0.tar.gz cmake-3.20.0

# Install wgrib2
RUN wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz \
  && tar -zxvf wgrib2.tgz \
  && cd grib2 \
  && make \
  && cp wgrib2/wgrib2 /usr/local/bin/ \
  && cd .. \
  && rm -rf wgrib2.tgz grib2

# Set user and group as in your working machine
ARG user=flexpart
ARG group=root
ARG uid=1002
ARG gid=1002
# RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/sh -m ${user}

#
# Download, modify and compile FLEXPART 10
#

COPY flexpart_v10.4/ flexpart_v10.4
RUN chown -R flexpart /flexpart_v10.4/

RUN cd flexpart_v10.4/src \
  && cp makefile makefile_local \
  && sed -i '74 a INCPATH1 = /usr/include\nINCPATH2 = /usr/include\nLIBPATH1 = /usr/lib\n F90 = gfortran' makefile_local \
  && sed -i 's/LIBS = -lgrib_api_f90 -lgrib_api -lm -ljasper $(NCOPT)/LIBS = -leccodes_f90 -leccodes -lm -ljasper $(NCOPT)/' makefile_local \
  && make mpi ncf=yes -f makefile_local \
  && make clean \
  && if ./FLEXPART_MPI | grep -q 'Welcome to FLEXPART'; then echo "Test FLEXPART binary successfully."; else echo "Error on testing FLEXPART binary." && false; fi

#
# Compile SIMFLEX
#

COPY simflex_v1/ /simflex_v1
RUN chown -R flexpart /simflex_v1/

RUN cd /simflex_v1/src \
  && gfortran -c m_parse.for m_simflex.for \
  && gfortran *.f90 *.for -I/usr/include/ -L/usr/lib/ -lnetcdff -lnetcdf -o simflex \
  && if ./simflex | grep -q 'Starting SIMFLEX'; then echo "Test simflex binary successfully."; else echo "Error on testing simflex binary." && false; fi

COPY calculation/ /calculation
RUN chown -R flexpart /calculation/

# COPY grib_data/ /data/grib_data

# Switch to user flexpart
USER ${uid}:${gid}

# provide flexpart and simflex binaries to the new user PATH
ENV PATH /simflex_v1/src/:$PATH
ENV PATH /flexpart_v10.4/src/:$PATH

WORKDIR /calculation

CMD ["python3", "-u", "/calculation/parser.py"]
