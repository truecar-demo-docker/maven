FROM registry.dev.true.sh/jenkins/base:20170720212202


ARG OPENCV_VERSION=4.1.0
ARG HADOOP_VERSION=2.6.4
ARG PROTOBUF_VERSION=2.5.0



ARG PRECACHEPKGS="boto3 numpy pandas"
ENV PYENV_ROOT="/var/pyenv"
ENV PATH="/var/cache/virtualenv/bin:${PYENV_ROOT}/shims:${PATH}"
ENV XDG_CACHE_HOME="/var/tmp"

ENV JAVA_OPTS="-Dorg.apache.commons.jelly.tags.fmt.timeZone=America/Los_Angeles -Dhudson.remoting.Launcher.pingIntervalSec=-1"

### jenkins slave
RUN  apt-get update \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
  && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  && add-apt-repository "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 \
  && apt-get update \
  && apt-get -qqy --no-install-recommends install \
    ansible \
    ant \
    build-essential \
    cmake \
    docker-ce \
    docker-compose \
    libbz2-dev \
    libjasper-dev \
    libjpeg8-dev \
    libpng12-dev \
    libsnappy-dev \
    libssl-dev \
    libtiff5-dev \
    libffi-dev \
    liblzma-dev \
    libncurses5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxmlsec1-dev \
    llvm \
    xz-utils \
    zlib1g-dev \
    make \
    maven \
    pkg-config \
    python-numpy \
    python2.7-dev \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/man \
    /usr/share/doc \
    /usr/share/doc-base \
  && mkdir -p /var/cache/virtualenv \
  && git clone https://github.com/pyenv/pyenv.git /var/pyenv \
  && chown jenkins:jenkins /var/pyenv /var/cache/virtualenv


### opencv
RUN mkdir -p /build/opencv_source \
  && curl -sSL https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz \
  | tar -C /build/opencv_source --strip-components=1 -xzf - \
  && ( cd /build ; export PATH=${JAVA_HOME}/bin:${PATH} ; \
    cmake -Wno-dev \
      -D BUILD_EXAMPLES=OFF \
      -D BUILD_PERF_TESTS=OFF \
      -D BUILD_SHARED_LIBS=OFF \
      -D BUILD_TESTS=OFF \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D INSTALL_C_EXAMPLES=OFF \
      -D INSTALL_PYTHON_EXAMPLES=OFF \
      -D PYTHON_EXECUTABLE=/usr/bin/python2.7 opencv_source ) \
    && ( cd /build ; make install ) && rm -rf /build \
    && ln -s /usr/local/share/java/opencv4/opencv-410.jar \
            ${JAVA_HOME}/lib/opencv-410.jar \
    && ln -s /usr/local/share/java/opencv4/libopencv_java410.so \
            /usr/lib/libopencv_java410.so

### protocol buffers (hadoop requires an old version)
RUN mkdir -p /build/protobuf \
  && curl -sSL https://github.com/google/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-${PROTOBUF_VERSION}.tar.gz \
  | tar -C /build/protobuf --strip-components=1 -xzf - \
  && (cd /build/protobuf ; ./configure --prefix=/usr ; make install) \
  && rm -rf /build

### hadoop native
RUN mkdir -p /build/hadoop_source \
  && curl -sSL https://github.com/apache/hadoop/archive/rel/release-${HADOOP_VERSION}.tar.gz \
  | tar -C /build/hadoop_source --strip-components=1 -xzf - \
  && (cd /build/hadoop_source ; export PATH=${JAVA_HOME}/bin:/usr/local/bin:${PATH} ; \
    mvn package -Pdist,native -Dmaven.javadoc.skip=true -DskipTests) \
  && mv /build/hadoop_source/hadoop-dist/target/hadoop-${HADOOP_VERSION} /usr/local/hadoop \
  && rm -rf /build && apt-get autoremove -yqq --purge maven \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/man \
    /usr/share/doc \
    /usr/share/doc-base

RUN apt update -y
RUN apt-get install xmlstarlet -y
RUN wget http://ftp.wayne.edu/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz -P /usr/local \
    && tar xf /usr/local/apache-maven-*.tar.gz -C /usr/local \
    && ln -s /usr/local/apache-maven-3.6.3 /usr/local/apache-maven

ENV M2_HOME=/usr/local/apache-maven
ENV MAVEN_HOME=/usr/local/apache-maven
ENV PATH="${M2_HOME}/bin:${PATH}"

# install python
RUN \
  /var/pyenv/bin/pyenv install 3.6.8 && echo "3.6.8" > /var/pyenv/version && \
  rm -f /var/pyenv/shims/python

# setup shared virtualenv
RUN python3 -m venv /var/cache/virtualenv && hash -r && \
  python3 -m pip install --upgrade \
    pip \
    awscli \
    setuptools \
    ${PRECACHEPKGS} \
  && rm -f /var/cache/virtualenv/bin/python
