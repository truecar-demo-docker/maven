FROM maven:3-jdk-8

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
      ant \
      build-essential \
      bzip2 \
      cmake \
      libbz2-dev \
      libsnappy-dev \
      libssl1.0-dev \
      make \
      pkg-config \
      python \
      zlib1g \
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

ARG HADOOP_VERSION=2.6.4
### hadoop native
RUN mkdir -p /build/hadoop_source \
 && curl -sSL https://github.com/apache/hadoop/archive/rel/release-${HADOOP_VERSION}.tar.gz \
  | tar -C /build/hadoop_source --strip-components=1 -xzf - \
 && ( cd /build/hadoop_source \
   && export PATH=${JAVA_HOME}/bin:/usr/local/bin:${PATH} \
   && mvn package -Pdist,native -Dmaven.javadoc.skip=true -DskipTests -X ) \
 && mv /build/hadoop_source/hadoop-dist/target/hadoop-${HADOOP_VERSION} /usr/local/hadoop \
 && rm -rf /build

ENV LD_LIBRARY_PATH /usr/local/hadoop/lib/native

## opencv
# ARG OPENCV_VERSION=2.4.9
# RUN apt-get update \
#  && apt-get install --no-install-recommends -y \
#         libjasper-dev \
#         libjpeg-dev \
#         libpng-dev \
#         libtiff5-dev \
#         python-numpy \
#         python2.7-dev \
#  && mkdir -p /build/opencv_source \
#  && curl -sSL https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz | tar -C /build/opencv_source --strip-components=1 -xzf - \
#  && ( cd /build && export PATH=${JAVA_HOME}/bin:${PATH} \
#    && cmake -Wno-dev \
#         -D ENABLE_PRECOMPILED_HEADERS=OFF \
#         -D BUILD_EXAMPLES=OFF \
#         -D BUILD_PERF_TESTS=OFF \
#         -D BUILD_SHARED_LIBS=OFF \
#         -D BUILD_TESTS=OFF \
#         -D CMAKE_BUILD_TYPE=Release \
#         -D CMAKE_INSTALL_PREFIX=/usr/local \
#         -D INSTALL_C_EXAMPLES=OFF \
#         -D INSTALL_PYTHON_EXAMPLES=OFF \
#         -D PYTHON_EXECUTABLE=/usr/bin/python2.7 \
#         opencv_source ) \
#  && ( cd /build && make install ) \
#  && rm -rf /build \
#  && ln -s /usr/local/share/OpenCV/java/opencv-249.jar ${JAVA_HOME}/lib/opencv-249.jar \
#  && ln -s /usr/local/share/OpenCV/java/libopencv_java249.so /usr/lib/libopencv_java249.so

# N.B: OpenCV 2.4.9 is really tough to build using modern tools. See https://github.com/opencv/opencv/issues/6195
# The above code will happily build v2.4.13, but to avoid forcing downstream upgrades, for now, just copy the jars from our current jenkins slave image
COPY --from=registry.dev.true.sh/jenkins/slave:20181211140057 /usr/local/share/OpenCV/java/libopencv_java249.so /usr/lib/libopencv_java249.so
COPY --from=registry.dev.true.sh/jenkins/slave:20181211140057 /usr/local/share/OpenCV/java/opencv-249.jar ${JAVA_HOME}/lib/opencv-249.jar