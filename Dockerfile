FROM debian:stretch

ARG RPI_FIRMWARE_BASE_URL='http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware'
ARG RPI_FIRMWARE_VERSION='20180313-1'

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  sudo \
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
  python \
  python-dev \
  python-pip \
  python3 \
  python3-dev \
  python3-pip \
  htop \
  apt-utils \
  locales \
  ca-certificates \
  && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

WORKDIR /tmp

RUN wget -O /tmp/libraspberrypi0_1.${RPI_FIRMWARE_VERSION}_armhf.deb \
  ${RPI_FIRMWARE_BASE_URL}/libraspberrypi0_1.${RPI_FIRMWARE_VERSION}_armhf.deb \
  && wget -O /tmp/libraspberrypi-dev_1.${RPI_FIRMWARE_VERSION}_armhf.deb \
  ${RPI_FIRMWARE_BASE_URL}/libraspberrypi-dev_1.${RPI_FIRMWARE_VERSION}_armhf.deb \
  && dpkg-deb -x /tmp/libraspberrypi0_1.${RPI_FIRMWARE_VERSION}_armhf.deb / \
  && dpkg-deb -x /tmp/libraspberrypi-dev_1.${RPI_FIRMWARE_VERSION}_armhf.deb / \
  && sed -i 's/^Libs:.*$/\0 -lvcos/' /opt/vc/lib/pkgconfig/vcsm.pc \
  && rm /tmp/libraspberrypi0_1.${RPI_FIRMWARE_VERSION}_armhf.deb /tmp/libraspberrypi-dev_1.${RPI_FIRMWARE_VERSION}_armhf.deb

RUN curl -sLO http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.23.0.tar.xz \
  && tar xvJf crosstool-ng-1.23.0.tar.xz \
  && cd crosstool-ng-1.23.0 \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && rm -rf crosstool-ng-1.23.0 crosstool-ng-1.23.0.tar.xz