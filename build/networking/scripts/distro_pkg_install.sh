#!/bin/bash
#Copyright (C) 2022 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#
# Version 0.1.0

# shellcheck source=networking/scripts/os_ver_details.sh
SCRIPTS_DIR=/root/scripts
source "${SCRIPTS_DIR}/os_ver_details.sh"
get_os_ver_details

usage() {
    echo ""
    echo "Usage:"
    echo "distro_pkg_install.sh: -b -d"
    echo ""
    echo "  -b: Development - Installs all packages needed for development"
    echo "  -d: Deployment - Installs minimal packages needed for runtime"
    echo ""
}

# Default settings
INSTALL_DEVELOPMENT_PKGS=n
INSTALL_DEPLOYMENT_PKGS=n

# Fedora distro packages instll methods
fedora_install_build_pkgs() {
    echo "Installing packages required for development"
    dnf -y update
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
        numactl-devel \
        which

    python -m pip install --upgrade pip
    python -m pip install grpcio
    python -m pip install ovspy
    python -m pip install protobuf==3.20.1
    python -m pip install p4runtime
    pip3 install pyelftools
    pip3 install scapy
    pip3 install six

    # Cleanup
    dnf -y clean all
    rm -rf /var/cache/yum
    rm -rf /var/cache/dnf
    rm -rf /root/.cache/pip

}

fedora_install_deployment_pkgs() {
    echo "Installing packages required for deployment"
    dnf install -y numactl-devel \
        libedit-devel \
        libunwind \
        libnl3-devel \
        python \
        pip \
        procps-ng \
        iproute \
        net-tools \
        iputils

    python -m pip install --upgrade pip
    python -m pip install grpcio
    python -m pip install ovspy
    python -m pip install protobuf==3.20.1
    python -m pip install p4runtime

    # Cleanup
    dnf -y clean all
    rm -rf /var/cache/yum
    rm -rf /var/cache/dnf
    rm -rf /root/.cache/pip
}

fedora_install_default_pkgs() {
    echo "Installing packages required for runtime"
    dnf install -y boost-iostreams \
        boost-devel \
        gmp-devel \
        numactl-devel \
        libedit-devel \
        libunwind \
        libnl3-devel \
        python \
        pip \
        procps-ng \
        iproute \
        net-tools \
        iputils

    python -m pip install --upgrade pip
    python -m pip install grpcio
    python -m pip install ovspy
    python -m pip install protobuf==3.20.1
    python -m pip install p4runtime

    # Cleanup
    dnf -y clean all
    rm -rf /var/cache/yum
    rm -rf /var/cache/dnf
    rm -rf /root/.cache/pip
}

# Ubuntu distro packages instll methods
ubuntu_install_build_pkgs() {
    echo "Installing packages required for development"
    apt-get update
    apt-get install -y apt-utils \
        git \
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
        vim \
        numactl \
        sudo \
        "${PYTHON_PKG_NAME}"

    python3 -m pip install --no-cache-dir --upgrade pip
    python3 -m pip install --no-cache-dir grpcio
    python3 -m pip install --no-cache-dir ovspy \
        protobuf=="${PROTOBUF_VER}" \
        p4runtime \
        pyelftools \
        scapy \
        six \
        cmake>=3.15.0 \
        meson==0.59.4 \
        ninja>=1.8.2

    # Cleanup
    apt-get -y clean all
    rm -rf /var/cache/yum
    rm -rf /var/cache/dnf
    rm -rf /root/.cache/pip
}

ubuntu_install_deployment_pkgs() {
    echo "Installing packages required for deployment"
    apt-get update
    apt-get install -y numactl \
        libedit-dev \
        libnl-route-3-dev python \
        python3-setuptools \
        python3-pip \
        "${PYTHON_PKG_NAME}" \
        "${EXTRA_PKGS}" \
        libunwind-dev \
        sudo \
        net-tools \
        iproute2 \
        vim

    python3 -m pip install --no-cache-dir --upgrade pip
    python3 -m pip install --no-cache-dir grpcio
    python3 -m pip install --no-cache-dir ovspy \
        protobuf=="${PROTOBUF_VER}" \
        p4runtime

    # Cleanup
    apt-get -y clean all
    rm -rf /var/cache/yum
    rm -rf /var/cache/dnf
    rm -rf /root/.cache/pip
}

ubuntu_install_default_pkgs() {
    echo "Installing packages required for runtime"
    apt-get update
    apt-get install -y libboost-iostreams-dev \
        libboost-dev \
        libgmp-dev \
        libgc-dev \
        numactl \
        libedit-dev \
        libnl-route-3-dev python \
        python3-setuptools \
        python3-pip \
        "${EXTRA_PKGS}" \
        "${PYTHON_PKG_NAME}" \
        libunwind-dev \
        sudo \
        net-tools \
        iproute2 \
        vim

    python3 -m pip install --no-cache-dir --upgrade pip
    python3 -m pip install --no-cache-dir grpcio
    python3 -m pip install --no-cache-dir ovspy \
        protobuf=="${PROTOBUF_VER}" \
        p4runtime

    # Cleanup
    apt-get -y clean all
    rm -rf /var/cache/yum
    rm -rf /var/cache/dnf
    rm -rf /root/.cache/pip
}

ubuntu_install_pkgs() {
    echo "Installing Ubuntu packages..."
    if [ "$BASE_IMG" = "ubuntu:18.04" ] ; then
        PROTOBUF_VER=3.19.4
        PYTHON_PKG_NAME="python-pip"
        EXTRA_PKGS="language-pack-en"
    else
        PROTOBUF_VER=3.20.1
        PYTHON_PKG_NAME="pip"
        EXTRA_PKGS=""
    fi

    if [ "${INSTALL_DEVELOPMENT_PKGS}" == "y" ]
    then
        ubuntu_install_build_pkgs
    elif [ "${INSTALL_DEPLOYMENT_PKGS}" == "y" ]
    then
        ubuntu_install_deployment_pkgs
    else
        ubuntu_install_default_pkgs
    fi
}

fedora_install_pkgs() {
    echo "Installing Fedora packages..."
    if [ "${INSTALL_DEVELOPMENT_PKGS}" == "y" ]
    then
        fedora_install_build_pkgs
    elif [ "${INSTALL_DEPLOYMENT_PKGS}" == "y" ]
    then
        fedora_install_deployment_pkgs
    else
        fedora_install_default_pkgs
    fi
}

# Main script
# Process commandline arguments
while getopts bd flag
do
    case "${flag}" in
        b)
            INSTALL_DEVELOPMENT_PKGS=y
            ;;
        d)
            INSTALL_DEPLOYMENT_PKGS=y
            ;;
        *)
            usage
            exit
            ;;
    esac
done

if [ "${OS}" = "Ubuntu" ]
then
    ubuntu_install_pkgs
else
    fedora_install_pkgs
fi
