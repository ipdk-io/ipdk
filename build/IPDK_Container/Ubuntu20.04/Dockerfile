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
    build-essential \
    git \
    sudo \
    meson \
    cmake \
    gdb \
    libtool \
    autoconf \
    autoconf-archive \
    automake \
    scapy \
    iproute2 \
    net-tools \
    libgflags-dev \
    iputils-ping \
    libcctz2 \
    libjson-c-dev \
    libffi-dev \
    libssl-dev \
    python \
    python3-cffi \
    python3-pip \
    libedit-dev \
    libexpat1-dev \
    pip \
    flex \
    bison \
    libgc-dev \
    vim \
    libboost-system-dev \
    libboost-graph-dev \
    libboost-thread-dev \
    libboost-program-options-dev \
    libboost-test-dev \
    libboost-dev \
    libboost-iostreams-dev \
    libboost-graph-dev \
    libboost-all-dev \
    libgc-dev libgmp-dev && \
    apt-get -y clean all

# Installing all PYTHON packages
RUN pip install --upgrade pip && \
    pip install grpcio \
    ovspy \
    protobuf \
    p4runtime \
    pyelftools

FROM base AS p4-ovs-container
WORKDIR /root
COPY ./scripts scripts
COPY ./examples /root/examples
COPY ./start_p4ovs.sh /root/start_p4ovs.sh
COPY ./run_ovs_cmds /root/run_ovs_cmds
RUN source /root/start_p4ovs.sh /root
#ADD ./start_p4ovs.sh /root/start_p4ovs
#ENTRYPOINT exec /root/start_p4ovs.sh /root

# Build P4-OVS
# RUN /root/start_p4ovs.sh /root
