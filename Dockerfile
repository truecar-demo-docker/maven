FROM centos:7.9.2009

ARG OPENCV_VERSION=4.1.0
ARG PYTHON_VERSION=3.8.6
ARG HADOOP_NATIVE=CDH-7.2.7-1.cdh7.2.7.p0.9408337-hadoop-native.tar.bz2

ENV PYENV_ROOT="/usr/local/pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/hadoop/lib/native
ENV XDG_CACHE_HOME="/var/tmp"

RUN yum update -y && \
  yum install -y maven \
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
    readline-devel \
    sqlite-devel \
    unzip \
    xmlsec1-devel \
    xz \
    xz-devel \
    zip \
    zlib-devel && \
  yum clean all

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
  mkdir -p /build/opencv_source && \
  curl -sSL https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz | tar -C /build/opencv_source --strip-components=1 -xzf -  && \
  ( cd /build && export PATH=${JAVA_HOME}/bin:${PATH} && \
  sed -i '/add_extra_compiler_option(-Werror=address)/d' opencv_source/cmake/OpenCVCompilerOptions.cmake && \
  cmake -Wno-dev \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTS=OFF \
        -D BUILD_opencv_core=ON \
        -D BUILD_opencv_imgcodecs=ON \
        -D BUILD_opencv_imgproc=ON \
        -D BUILD_JAVA=ON \
        -D BUILD_opencv_java=ON \
        -D BUILD_opencv_java_bindings_gen=ON \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D ENABLE_PRECOMPILED_HEADERS=OFF \
        -D INSTALL_C_EXAMPLES=OFF \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D PYTHON_EXECUTABLE=${PYENV_ROOT}/shims/python3 opencv_source ) && \
  ( cd /build && make install ) && \
  rm -rf /build && mkdir -p /build && \
  ln -s /usr/local/share/java/opencv4/opencv-410.jar ${JAVA_HOME}/lib/opencv-410.jar && \
  ln -s /usr/local/share/java/opencv4/libopencv_java410.so /usr/lib/libopencv_java410.so

WORKDIR /build
