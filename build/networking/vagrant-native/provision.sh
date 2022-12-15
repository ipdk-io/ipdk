#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#
# Version 0.1.0

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

apt-get update

apt-get install -y apt-utils \
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
        sudo \
        make \
        cloud-image-utils \
        telnet \
        qemu-kvm

apt-get --allow-downgrades install -y libssl1.1="1.1.1f-1ubuntu2.16" \
        libssl-dev

pip install --upgrade pip
pip install grpcio \
            ovspy \
            protobuf==3.20.3 \
            p4runtime \
            pyelftools \
            scapy \
            six
