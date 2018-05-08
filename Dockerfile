FROM debian:stretch

ARG CROSSTOOL_NG_VERSION="crosstool-ng-1.23.0"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  sudo \
  locales \
  git \
  wget \
  curl \
  gcc \
  g++ \
  cmake \
  autoconf \
  automake \
  libtool \
  build-essential \
  pkg-config \
  gperf \
  bison \
  flex \
  texinfo \
  bzip2 \
  xz-utils \
  help2man \
  gawk \
  make \
  libncurses5-dev \
  libomxil-bellagio-dev \
  && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

WORKDIR /tmp
ARG RPI_FIRMWARE_BASE_URL='http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware'
ARG RPI_FIRMWARE_VERSION='20180417-1'

RUN wget -O /tmp/libraspberrypi0_1.${RPI_FIRMWARE_VERSION}_armhf.deb \
  ${RPI_FIRMWARE_BASE_URL}/libraspberrypi0_1.${RPI_FIRMWARE_VERSION}_armhf.deb \
  && wget -O /tmp/libraspberrypi-dev_1.${RPI_FIRMWARE_VERSION}_armhf.deb \
  ${RPI_FIRMWARE_BASE_URL}/libraspberrypi-dev_1.${RPI_FIRMWARE_VERSION}_armhf.deb \
  && dpkg-deb -x /tmp/libraspberrypi0_1.${RPI_FIRMWARE_VERSION}_armhf.deb / \
  && dpkg-deb -x /tmp/libraspberrypi-dev_1.${RPI_FIRMWARE_VERSION}_armhf.deb / \
  && sed -i 's/^Libs:.*$/\0 -lvcos/' /opt/vc/lib/pkgconfig/vcsm.pc \
  && rm /tmp/libraspberrypi0_1.${RPI_FIRMWARE_VERSION}_armhf.deb /tmp/libraspberrypi-dev_1.${RPI_FIRMWARE_VERSION}_armhf.deb

RUN curl -sLO http://crosstool-ng.org/download/crosstool-ng/${CROSSTOOL_NG_VERSION}.tar.xz \
  && tar xvJf ${CROSSTOOL_NG_VERSION}.tar.xz \
  && cd ${CROSSTOOL_NG_VERSION} \
  && ./configure --prefix=/opt/cross \
  && make \
  && make install \
  && cd .. \
  && rm -rf ${CROSSTOOL_NG_VERSION} ${CROSSTOOL_NG_VERSION}.tar.xz
ENV PATH /opt/cross/bin:$PATH
ARG USER_NAME="pi3"

RUN useradd -m ${USER_NAME} \
  && echo  ${USER_NAME}:${USER_NAME} | chpasswd \
  && adduser ${USER_NAME} sudo \
  && echo "${USER_NAME} ALL=NOPASSWD: ALL" >> /etc/sudoers.d/${USER_NAME}

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}
ENV HOME /home/${USER_NAME}

# set locale
RUN sudo sed 's/.*en_US.UTF-8/en_US.UTF-8/' -i /etc/locale.gen
RUN sudo locale-gen
RUN sudo update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV PATH ${HOME}/.local/bin:$PATH
RUN echo "export PATH=$PATH" >> ${HOME}/.bashrc
CMD ["/bin/bash"]

RUN mkdir armv8-rpi3-linux-gnueabihf \
  && cd armv8-rpi3-linux-gnueabihf \
  && ct-ng armv8-rpi3-linux-gnueabihf \
  && sed 's/^# CT_CC_GCC_LIBGOMP is not set/CT_CC_GCC_LIBGOMP=y/' -i .config \
  && sed 's/CT_LOG_PROGRESS_BAR/# CT_LOG_PROGRESS_BAR/' -i .config \
  && ct-ng build \
  && cd .. \
  && rm -rf armv8-rpi3-linux-gnueabihf
ENV PATH $HOME/x-tools/armv8-rpi3-linux-gnueabihf/bin:$PATH

RUN mkdir aarch64-rpi3-linux-gnueabihf \
  && cd aarch64-rpi3-linux-gnueabihf \
  && ct-ng aarch64-rpi3-linux-gnueabi \
  && sed 's/^CT_ARCH_FLOAT="auto"/CT_ARCH_FLOAT="hard"/' -i .config \
  && echo 'CT_ARCH_ARM_TUPLE_USE_EABIHF=y' >> .config \
  && sed 's/^# CT_CC_GCC_LIBGOMP is not set/CT_CC_GCC_LIBGOMP=y/' -i .config \
  && sed 's/CT_LOG_PROGRESS_BAR/# CT_LOG_PROGRESS_BAR/' -i .config \
  && ct-ng build \
  && cd .. \
  && rm -rf aarch64-rpi3-linux-gnueabihf
ENV PATH $HOME/x-tools/aarch64-rpi3-linux-gnueabihf/bin:$PATH

RUN echo "export PATH=$PATH" >> ${HOME}/.bashrc