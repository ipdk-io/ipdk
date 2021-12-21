#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#
# Version 0.1.0

ARG OS_VERSION=${OS_VERSION}

FROM ubuntu:${OS_VERSION} AS base
LABEL maintainer="neha1.singh@intel.com"
ARG PROXY

SHELL ["/bin/bash", "-c"]

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Installing dependent packages required for DPDK Build
RUN apt-get update

RUN apt-get install -y apt-utils \
    git \
    meson \
    cmake \
    libtool \
    clang \
    gcc \
    g++ \
    autoconf \
    automake \
    autoconf-archive \
    libconfig++-dev \
    libgc-dev \
    unifdef \
    libffi-dev \
    libboost-iostreams-dev \
    libboost-graph-dev \
    llvm \
    pkg-config \
    flex libfl-dev \
    zlib1g-dev \
    iproute2 \
    net-tools \
    iputils-arping \
    iputils-ping \
    iputils-tracepath \
    python \
    pip \
    bison \
    python3-setuptools \
    python3-pip \
    python3-wheel \
    python3-cffi \
    libedit-dev \
    libgmp-dev \
    libexpat1-dev \
    libboost-dev \
    google-perftools \
    curl \
    connect-proxy \
    coreutils \
    sudo && \
    apt-get -y clean all

# Installing all PYTHON packages
RUN pip install --upgrade pip && \
    pip install grpcio \
    ovspy \
    protobuf \
    p4runtime \
    pyelftools \
    scapy \
    six

FROM base AS p4-ovs-container
WORKDIR /root
COPY ./scripts scripts
COPY ./examples /root/examples
COPY ./start_p4ovs.sh /root/start_p4ovs.sh
COPY ./run_ovs_cmds /root/run_ovs_cmds
RUN /root/start_p4ovs.sh /root && \
    rm -rf /root/P4OVS_DEPS_SRC_CODE && \
    cd /root/P4-OVS/ && make clean
