FROM centos:7.9.2009

ARG OPENCV_VERSION=4.1.0
ARG PYTHON_VERSION=3.8.6
ARG HADOOP_NATIVE=CDH-7.2.7-1.cdh7.2.7.p0.9408337-hadoop-native.tar.bz2

ENV PYENV_ROOT="/usr/local/pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/hadoop/lib/native
ENV XDG_CACHE_HOME="/var/tmp"

RUN yum update -y && \
  yum install -y wget \
    ant \
    bzip2 \
    bzip2-devel \
    cmake \
    curl \
    gcc \
    gcc-c++ \
    git \
    libffi-devel \
    libpng-devel \
    libtiff-devel \
    libxml2-devel \
    llvm \
    make \
    ncurses-devel \
    openjpeg-devel \
    openssl-devel \
    python3 \
    python3-devel \
    python3-pip \
    readline-devel \
    sqlite-devel \
    unzip \
    xmlsec1-devel \
    xz \
    xz-devel \
    zip \
    zlib-devel \
    python-devel \
    postgresql-devel \
    java-11-openjdk-devel \
    java-11-openjdk && \
  yum clean all

RUN \
 echo 2 | update-alternatives --config javac

RUN \
  echo 2 | update-alternatives --config java

## hadoop native
RUN \
 curl -sSL https://artifactory.corp.tc/artifactory/misc-static/${HADOOP_NATIVE} | \
  tar -C /usr/local -xjf -

## python
RUN \
  git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
  ${PYENV_ROOT}/bin/pyenv install ${PYTHON_VERSION} && echo ${PYTHON_VERSION} > ${PYENV_ROOT}/version && \
  ${PYENV_ROOT}/shims/python3 -m pip install --upgrade pip && \
  rm -f ${PYENV_ROOT}/shims/python # python will remain python2

## opencv
RUN \
  rpm -Uvh https://artifactory.corp.tc/artifactory/zag-centos6x/TCOpenCV-4.1.0-3.x86_64.rpm

RUN \
    wget https://dlcdn.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz -P /tmp && \
    tar xf /tmp/apache-maven-3.8.4-bin.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.8.4/bin/mvn /usr/bin/mvn

WORKDIR /build
