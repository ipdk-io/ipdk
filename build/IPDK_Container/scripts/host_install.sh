#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#
# Version 0.1.0

# shellcheck source=scripts/os_ver_details.sh
source os_ver_details.sh
get_os_ver_details

usage() {
    echo ""
    echo "Usage:"
    echo "host_install.sh: -s -p"
    echo ""
    echo "  -p: Proxy to use"
    echo "  -s: Skip installing and building dependencies"
    echo ""
}

INSTALL_DEPENDENCIES=y

# Process commandline arguments
while getopts sp: flag
do
    case "${flag}" in
        p) 
            http_proxy="${OPTARG}"
            https_proxy="${OPTARG}"
            export http_proxy
            export https_proxy
            ;;
        s)
            INSTALL_DEPENDENCIES=n
            ;;
        *)
            usage
            exit
            ;;
    esac
done

export INSTALL_DEPENDENCIES

if [ "${OS}" = "Ubuntu" ]
then
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
        make

        pip install --upgrade pip && \
        pip install grpcio \
            ovspy \
            protobuf \
            p4runtime \
            pyelftools \
            scapy \
            six
else
    dnf -y update && \
    dnf install -y git \
    meson \
    cmake \
    libtool \
    clang \
    gcc \
    g++ \
    autoconf \
    automake \
    autoconf-archive \
    libconfig \
    libgc-devel \
    unifdef \
    libffi-devel \
    boost-iostreams \
    boost-graph \
    llvm \
    pkg-config \
    flex flex-devel \
    zlib-devel \
    iproute \
    net-tools \
    iputils \
    python \
    pip \
    bison \
    python3-setuptools \
    python3-pip \
    python3-wheel \
    python3-cffi \
    libedit-devel \
    gmp-devel \
    expat-devel \
    boost-devel \
    google-perftools \
    curl \
    connect-proxy \
    coreutils \
    which

    # Installing all PYTHON packages
    python -m pip install --upgrade pip && \
    python -m pip install grpcio && \
    python -m pip install ovspy && \
    python -m pip install protobuf && \
    python -m pip install p4runtime && \
    pip3 install pyelftools && \
    pip3 install scapy && \
    pip3 install six
fi

cd /root || exit
cp -r /git/ipdk/scripts .
cp -r /git/ipdk/examples .
cp /git/ipdk/start_p4ovs.sh start_p4ovs.sh
cp /git/ipdk/run_ovs_cmds run_ovs_cmds
popd

export OS_VERSION=20.04
export IMAGE_NAME=ipdk/p4-ovs-ubuntu20.04
export REPO=${PWD}
TAG="$(cd "${REPO}" && git rev-parse --short HEAD)"
export TAG

echo "$OS_VERSION"
echo "$IMAGE_NAME"
echo "$REPO"
echo "$TAG"

/root/start_p4ovs.sh /root && \
    rm -rf /root/P4OVS_DEPS_SRC_CODE && \
    cd /root/P4-OVS/ && make clean
