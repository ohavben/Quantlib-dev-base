#######################################
# CI image:
#   the one used by your CI server
#######################################
FROM ubuntu:20.04 

ARG DEBIAN_FRONTEND=noninteractive
ARG CLANG_VERSION=12

# fix "Missing privilege separation directory":
# https://bugs.launchpad.net/ubuntu/+source/openssh/+bug/45234
RUN mkdir -p /run/sshd && \
  apt-get update && apt-get -y dist-upgrade && \
  apt-get -y install --fix-missing \
  build-essential \
  bzip2 \
  ccache \
  clang-${CLANG_VERSION} \
  clangd-${CLANG_VERSION} \
  clang-format-${CLANG_VERSION} \
  clang-tidy-${CLANG_VERSION} \
  cmake \
  cppcheck \
  curl \
  doxygen \
  gcovr \
  git \
  graphviz \
  libclang-${CLANG_VERSION}-dev \
  linux-tools-generic \
  lldb-${CLANG_VERSION} \
  lld-${CLANG_VERSION} \
  lsb-release \
  ninja-build \
  python3 \
  python3-pip \
  shellcheck \
  software-properties-common \
  ssh \
  sudo \
  tar \
  unzip \
  valgrind \
  libboost-all-dev \
  automake \
  autoconf \
  libtool \
  wget && \
  \
  pip install behave conan pexpect requests && \
  apt-get autoremove -y && apt-get clean && \
  \
  for c in $(ls /usr/bin/clang*-${CLANG_VERSION}); do link=$(echo $c | sed "s/-${CLANG_VERSION}//"); ln -sf $c $link; done && \
  update-alternatives --install /usr/bin/cc cc /usr/bin/clang 1000 && \
  update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 1000 

# build include-what-you-use in the version that matches CLANG_VERSION (iwyu branch name)
WORKDIR /var/tmp/build_iwyu
RUN curl -sSL https://github.com/include-what-you-use/include-what-you-use/archive/refs/heads/clang_${CLANG_VERSION}.zip -o temp.zip && \
  unzip temp.zip && rm temp.zip && mv include-what-you-use-clang_${CLANG_VERSION}/* . && rm -r include-what-you-use-clang_${CLANG_VERSION} && \
  cmake -DCMAKE_INSTALL_PREFIX=/usr -Bcmake-build && \
  cmake --build cmake-build --target install -- -j ${NCPU} && \
  ldconfig

WORKDIR /
RUN rm -rf /var/tmp/build_iwyu

#######################################
#  quantlib 
#######################################

ENV QUANTLIB /quantlib
ENV QUANTLIB_VERSION 1.22

WORKDIR /tmp
RUN wget https://github.com/lballabio/QuantLib/releases/download/QuantLib-v${QUANTLIB_VERSION}/QuantLib-${QUANTLIB_VERSION}.tar.gz -O QuantLib-${QUANTLIB_VERSION}.tar.gz && \
	mkdir ${QUANTLIB} && \
	tar xzf QuantLib-${QUANTLIB_VERSION}.tar.gz -C ${QUANTLIB} --strip-components=1 && \
	rm -f QuantLib-${QUANTLIB_VERSION}.tar.gz 

WORKDIR ${QUANTLIB}
RUN ./configure  && \
	make -j4 && \
	make install && \
  ldconfig

RUN apt-get clean
