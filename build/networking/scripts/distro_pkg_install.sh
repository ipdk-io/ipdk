#!/bin/bash
#Copyright (C) 2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#
# Version 0.1.0

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
        openssl-devel \
        libatomic \
        libnl3-devel \
        which

    python -m pip install --upgrade pip
    python -m pip install grpcio
    python -m pip install ovspy
    python -m pip install protobuf==3.20.3
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
    python -m pip install protobuf==3.20.3
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
        libatomic \
        iputils \
        psmisc

    python -m pip install --upgrade pip
    python -m pip install grpcio
    python -m pip install ovspy
    python -m pip install protobuf==3.20.3
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
        libssl-dev \
        libnl-route-3-dev \
        libatomic1 \
        libunwind-dev \
        wget \
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
        "cmake>=3.15.0" \
        meson==0.59.4 \
        "ninja>=1.8.2"

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
        vim \
        iputils-ping \
        psmisc

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
        PROTOBUF_VER=3.20.3
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
usage() {
    echo ""
    echo "Usage:"
    echo "distro_pkg_install.sh: [--install-dev-pkgs] [--install-deployment-pkgs] -s|--scripts-dir"
    echo ""
    echo "  --install-dev-pkgs: Installs packages required for development"
    echo "  --install-deployment-pkgs: Installs packages required for deployment"
    echo "  -h|--help: Displays help"
    echo "  -s|--scripts-dir: Directory path where all utility scripts copied. [Default: /root/scripts]"
    echo "  Default: Installs packages required for running the modules"
    echo ""
}

# Parse command-line options.
SHORTOPTS=":h,s:"
LONGOPTS=help,install-dev-pkgs,install-deployment-pkgs,scripts-dir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
INSTALL_DEVELOPMENT_PKGS=n
INSTALL_DEPLOYMENT_PKGS=n
SCRIPTS_DIR=/root/scripts

# Process command-line options.
while true ; do
    case "${1}" in
    --install-dev-pkgs)
        INSTALL_DEVELOPMENT_PKGS=y
        shift ;;
    --install-deployment-pkgs)
        INSTALL_DEPLOYMENT_PKGS=y
        shift ;;
    -h|--help)
        usage
        exit 1 ;;
    -s|--scripts-dir)
        SCRIPTS_DIR="${2}"
        shift 2 ;;
    --)
        shift
        break ;;
    *)
        echo "Internal error!"
        exit 1 ;;
    esac
done

# Display argument data after parsing commandline arguments
echo ""
echo "INSTALL_DEVELOPMENT_PKGS: ${INSTALL_DEVELOPMENT_PKGS}"
echo "INSTALL_DEPLOYMENT_PKGS: ${INSTALL_DEPLOYMENT_PKGS}"
echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
echo ""

# shellcheck source=networking/scripts/os_ver_details.sh
. "${SCRIPTS_DIR}"/os_ver_details.sh
get_os_ver_details

if [ "${OS}" = "Ubuntu" ]
then
    ubuntu_install_pkgs
else
    fedora_install_pkgs
fi
