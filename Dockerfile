FROM maven:3-jdk-8

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
      build-essential \
      cmake \
      make \
      python \
      zlib1g-dev

ARG PROTOBUF_VERSION=2.5.0
### protocol buffers (hadoop requires an old version)
RUN mkdir -p /build/protobuf \
 && curl -sSL https://github.com/google/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-${PROTOBUF_VERSION}.tar.gz \
    | tar -C /build/protobuf --strip-components=1 -xzf - \
 && ( cd /build/protobuf \
   && ./configure --prefix=/usr \
   && make install ) \
 && rm -rf /build


RUN apt-get update \
  && apt-get install --no-install-recommends -y \
        ant \
        build-essential \
        cmake \
        bzip2 \
        libbz2-dev \
        libsnappy-dev \
        libssl-dev \
        libtiff5-dev \
        make \
        pkg-config \
        zlib1g \
        zlib1g-dev


# Hadoop < 3.0.0-beta1 fails to build on openssl 1.1.*
RUN mkdir -p /build/openssl /opt/openssl-1.0.2 \
 && curl -fsSL https://www.openssl.org/source/openssl-1.0.2l.tar.gz | tar -C /build/openssl --strip-components=1 -xzf - \
 && ( cd /build/openssl \
   && ./config --prefix=/opt/openssl-1.0.2 \
   && make \
   && make install ) \
 && rm -rf /build

ARG HADOOP_VERSION=2.6.4
### hadoop native
RUN mkdir -p /build/hadoop_source \
 && curl -sSL https://github.com/apache/hadoop/archive/rel/release-${HADOOP_VERSION}.tar.gz \
  | tar -C /build/hadoop_source --strip-components=1 -xzf - \
 && ( cd /build/hadoop_source \
   && export PATH=${JAVA_HOME}/bin:/usr/local/bin:${PATH} \
   && mvn package -Pdist,native -Dmaven.javadoc.skip=true -DskipTests -Dopenssl.prefix=/opt/openssl-1.0.2 -X ) \
 && mv /build/hadoop_source/hadoop-dist/target/hadoop-${HADOOP_VERSION} /usr/local/hadoop \
 && rm -rf /build

ENV LD_LIBRARY_PATH /usr/local/hadoop/lib/native

## opencv
# ARG OPENCV_VERSION=2.4.9
# RUN apt-get update \
#   && apt-get install --no-install-recommends -y \
#         libtiff5-dev \
# && mkdir -p /build/opencv_source \
#  && curl -sSL https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz | tar -C /build/opencv_source --strip-components=1 -xzf - \
#  && ( cd /build && export PATH=${JAVA_HOME}/bin:${PATH} \
#    && cmake -Wno-dev \
#         -D BUILD_EXAMPLES=OFF \
#         -D BUILD_PERF_TESTS=OFF \
#         -D BUILD_SHARED_LIBS=OFF \
#         -D BUILD_TESTS=OFF \
#         -D CMAKE_BUILD_TYPE=Release \
#         -D CMAKE_INSTALL_PREFIX=/usr/local \
#         -D INSTALL_C_EXAMPLES=OFF \
#         -D INSTALL_PYTHON_EXAMPLES=OFF \
#         -D PYTHON_EXECUTABLE=/usr/bin/python2.7 opencv_source ) \
#  && ( cd /build && make install ) \
#  && rm -rf /build \
#  && ln -s /usr/local/share/OpenCV/java/opencv-249.jar ${JAVA_HOME}/lib/opencv-249.jar \
#  && ln -s /usr/local/share/OpenCV/java/libopencv_java249.so /usr/lib/libopencv_java249.so
