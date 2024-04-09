# Copyright (C) 2016 by Ewan Barr
# Licensed under the Academic Free License version 3.0
# This program comes with ABSOLUTELY NO WARRANTY.
# You are free to modify and redistribute this code as long
# as you do not remove the above attribution and reasonably
# inform receipients that you have modified the original work.

FROM ubuntu:16.04

MAINTAINER : Vishnu Balakrishnan "vishnu@mpifr-bonn.mpg.de"
#CREDITS: Ewan Barr "ebarr@mpifr-bonn.mpg.de" (Largely based on)


RUN rm /bin/sh && ln -s /bin/bash /bin/sh 

# Suppress debconf warnings
ENV DEBIAN_FRONTEND noninteractive

# Create psr user which will be used to run commands with reduced privileges.
RUN adduser --disabled-password --gecos 'unprivileged user' psr && \
    echo "psr:psr" | chpasswd && \
    mkdir -p /home/psr/.ssh && \
    chown -R psr:psr /home/psr/.ssh

# Create space for ssh daemon and update the system
RUN echo 'deb http://us.archive.ubuntu.com/ubuntu trusty main multiverse' >> /etc/apt/sources.list && \
    mkdir /var/run/sshd && \
    apt-get -y check && \
    apt-get -y update && \
    apt-get install -y apt-utils apt-transport-https software-properties-common python-software-properties && \
    apt-get -y update --fix-missing && \
    apt-get -y upgrade 


# Install dependencies
RUN apt-get update
RUN apt-get update --fix-missing
RUN apt-get --no-install-recommends -y install \  

    build-essential \
    autoconf \
    autotools-dev \
    automake \
    pkg-config \
    csh \
    cmake \
    gcc \
    gfortran \
    wget \
    git \
    expect \	
    cvs \
    libcfitsio-dev \
    pgplot5 \
    swig2.0 \    
    python \
    python-dev \
    python-pip \
    python-qt4 \
    python-qt4-dbus \
    python-qt4-dev \
    python-tk \
    libfftw3-3 \
    libfftw3-bin \
    libfftw3-dev \
    libfftw3-single3 \
    libxml2 \
    libxml2-dev \
    libx11-dev \
    libpng12-dev \
    libpng3 \
    libpnglite-dev \   
    libglib2.0-0 \
    libglib2.0-dev \
    openssh-server \
    xorg \
    openbox \
    libhdf5-10 \
    libhdf5-cpp-11 \
    libhdf5-dev \
    libhdf5-serial-dev \
    libltdl-dev \
    gsl-bin \
    libgsl-dev \
    libgsl2 \
    openssh-server \
    docker.io \
    vim \
    emacs \
    gedit \
    bc \
    curl \
    && rm -rf /var/lib/apt/lists/* 

RUN apt-get -y clean
#RUN apt-get install libmysqlclient-dev

#RUN yum install tcsh
RUN pip install --upgrade pip 
WORKDIR /usr/bin
RUN rm pip
COPY pip /usr/bin/pip 



# Install python packages
RUN pip install pip -U && \
    pip install setuptools -U && \
    pip install numpy -U && \
    pip install scipy -U && \
    pip install matplotlib -U && \
    pip install pandas -U && \
    pip install APLpy -U && \ 
    pip install joblib -U && \
    pip install multiprocess -U && \
    pip install scikit-monaco -U && \
    pip install sympy -U 
#    pip install mysqlclient -U


RUN apt-get update -y && \
    apt-get --no-install-recommends -y install \
    autogen \
    libtool \
    libltdl-dev	
    

# Install Java

RUN apt-get install -y default-jdk && \
    rm -rf /var/lib/apt/lists/*

# Install tcsh

RUN apt-get update
RUN apt-get install tcsh



USER psr

# Java
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# PGPLOT
ENV PGPLOT_DIR /usr/lib/pgplot5
ENV PGPLOT_FONT /usr/lib/pgplot5/grfont.dat
ENV PGPLOT_INCLUDES /usr/include
ENV PGPLOT_BACKGROUND white
ENV PGPLOT_FOREGROUND black
ENV PGPLOT_DEV /xs

# Define home, psrhome, OSTYPE and create the directory
ENV HOME /home/psr
ENV PSRHOME /home/psr/software
ENV OSTYPE linux
RUN mkdir -p /home/psr/software
#RUN mkdir -p /home/psr/software/pulsarhunter
WORKDIR $PSRHOME

# Pull all repos

RUN wget http://www.pulsarastronomy.net/psrsoft/psrsoft.tar.gz && \
    tar -xvzf psrsoft.tar.gz && \
    rm -rf psrsoft.tar.gz 
RUN git clone https://bitbucket.org/psrsoft/tempo2.git 


RUN git clone git://git.code.sf.net/p/psrchive/code psrchive 
RUN git clone git://git.code.sf.net/p/tempo/tempo 
RUN git clone https://github.com/SixByNine/psrxml.git && \
    git clone https://github.com/ewanbarr/sigpyproc.git && \
    git clone https://github.com/scottransom/presto.git && \
    git clone https://github.com/scottransom/pyslalib.git && \
    wget http://www.atnf.csiro.au/people/pulsar/psrcat/downloads/psrcat_pkg.tar.gz && \
    tar -xvf psrcat_pkg.tar.gz -C $PSRHOME 

#RUN git clone git://git.code.sf.net/p/dspsr/code dspsr
RUN git config --global core.compression 0 
RUN git clone --depth 1 git://git.code.sf.net/p/dspsr/code dspsr 
WORKDIR $PSRHOME/dspsr
RUN git fetch --unshallow 
RUN git pull --all

#PSRSOFT: Sixproc + fftw + cfitsio + pgplot + pulsarhunter

WORKDIR $PSRHOME/psrsoft/config
RUN mv profile.example profile
WORKDIR $PSRHOME/psrsoft
RUN /bin/echo -e "y" | ./bin/psrsoft sixproc pulsarhunter
ENV PULSARHUNTER_HOME $PSRHOME/psrsoft/usr/share/pulsarhunter
ENV SIGPROC $PSRHOME/psrsoft/usr/bin

# PSRXML
ENV PSRXML $PSRHOME/psrxml
ENV PATH $PATH:$PSRXML/install/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PSRXML/install/lib
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PSRXML/install/include
WORKDIR $PSRXML
RUN autoreconf --install --warnings=none
RUN ./configure --prefix=$PSRXML/install && \
    make && \
    make install && \
    rm -rf .git

# tempo2
ENV TEMPO2 $PSRHOME/tempo2/T2runtime
ENV PATH $PATH:$PSRHOME/tempo2/T2runtime/bin
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PSRHOME/tempo2/T2runtime/include
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PSRHOME/tempo2/T2runtime/lib
WORKDIR $PSRHOME/tempo2
RUN sync && perl -pi -e 's/chmod \+x/#chmod +x/' bootstrap # Get rid of: returned a non-zero code: 126.
RUN ./bootstrap && \
    ./configure --x-libraries=/usr/lib/x86_64-linux-gnu --enable-shared --enable-static --with-pic F77=gfortran && \
    make -j $(nproc) && \
    make install && \
    make plugins-install && \
    rm -rf .git


# Tempo
ENV TEMPO $PSRHOME/tempo
ENV PATH $PATH:$PSRHOME/tempo/bin
WORKDIR $TEMPO
RUN ls -lrt 
RUN ./prepare && \
    ./configure --prefix=$PSRHOME/tempo && \
    make && \
    make install && \
    rm -rf .git


ENV PYTHONPATH /opt/conda/lib/python3.6/site-packages
# PSRCHIVE
ENV PSRCHIVE $PSRHOME/psrchive
ENV PATH $PATH:$PSRCHIVE/install/bin
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PSRCHIVE/install/include
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PSRCHIVE/install/lib
ENV PYTHONPATH $PSRCHIVE/install/lib/python2.7/site-packages/
WORKDIR $PSRCHIVE
RUN ./bootstrap && \
    ./configure --prefix=$PSRCHIVE/install --x-libraries=/usr/lib/x86_64-linux-gnu --with-psrxml-dir=$PSRXML/install --enable-shared --enable-static F77=gfortran LDFLAGS="-L"$PSRXML"/install/lib" LIBS="-lpsrxml -lxml2" && \
    make -j $(nproc) && \
    make && \
    make install && \
    rm -rf .git

WORKDIR $HOME
RUN echo "Predictor::default = tempo2" >> .psrchive.cfg && \
    echo "Predictor::policy = default" >> .psrchive.cfg

# DSPSR
ENV DSPSR $PSRHOME/dspsr
ENV PATH $PATH:$DSPSR/install/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$DSPSR/install/lib
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$DSPSR/install/include
WORKDIR $DSPSR
RUN ./bootstrap && \
    echo "bpsr caspsr fits sigproc" > backends.list && \
    ./configure --prefix=$DSPSR/install --x-libraries=/usr/lib/x86_64-linux-gnu && \
   make -j $(nproc) && \
  make && \
 make install


# Psrcat
ENV PSRCAT_FILE $PSRHOME/psrcat_tar/psrcat.db
ENV PATH $PATH:$PSRHOME/psrcat_tar
WORKDIR $PSRHOME/psrcat_tar
RUN /bin/bash makeit && \
    rm -f ../psrcat_pkg.tar.gz

# pyslalib
ENV PYSLALIB $PSRHOME/pyslalib
ENV PYTHONPATH PYSLALIB/install
WORKDIR $PYSLALIB
RUN python setup.py install --record list.txt --prefix=$PYSLALIB/install && \
    python setup.py clean --all && \
    rm -rf .git

# Presto
ENV PRESTO $PSRHOME/presto
ENV PATH $PATH:$PRESTO/bin
ENV LD_LIBRARY_PATH $PRESTO/lib
ENV PYTHONPATH $PYTHONPATH:$PRESTO/lib/python
WORKDIR $PRESTO/src
RUN rm -rf ../.git
#RUN make makewisdom
RUN make prep && \
    make
WORKDIR $PRESTO/python/ppgplot_src
#RUN mv _ppgplot.c _ppgplot.c_ORIGINAL && \
#    wget https://raw.githubusercontent.com/mserylak/pulsar_docker/master/ppgplot/_ppgplot.c
WORKDIR $PRESTO/python
RUN make && \
    echo "export PYTHONPATH=$PYTHONPATH:$PRESTO/lib/python" >> ~/.bashrc

# Sigpyproc
ENV SIGPYPROC_HOME $PSRHOME/sigpyproc
#ENV PATH $PATH:$SIGPYPROC/install/bin
WORKDIR $SIGPYPROC_HOME
USER root
RUN python setup.py install
#ENV LD_LIBRARY_PATH=/usr/local/lib
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$SIGPYPROC_HOME/lib/c
WORKDIR $HOME
RUN env | awk '{print "export ",$0}' > $HOME/.profile && \
    echo "source $HOME/.profile" >> $HOME/.bashrc



RUN pip install numba ipython
RUN rm -rf $PSRHOME/psrsoft/usr/bin/fake
COPY fake.c $PSRHOME/psrsoft/usr/src/sixproc/src/
WORKDIR $PSRHOME/psrsoft/usr/src/sixproc/src/
RUN make fake
WORKDIR $HOME
COPY phase_int_fullmodel.c get_templatebank.c check_same_templatebank_subet.c $PSRHOME/
RUN g++ $PSRHOME/phase_int_fullmodel.c -o $PSRHOME/phase_int_fullmodel.o -lgsl -lgslcblas
RUN gcc $PSRHOME/get_templatebank.c -o $PSRHOME/get_templatebank.o -lgsl -lgslcblas -lm -std=gnu89 
RUN gcc $PSRHOME/check_same_templatebank_subet.c -o $PSRHOME/check_same_templatebank_subet.o -lgsl -lgslcblas -lm -std=gnu89 
WORKDIR $HOME
USER root
