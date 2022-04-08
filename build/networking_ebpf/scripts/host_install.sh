#!/bin/bash
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# Version 0.1.0

set -x

# Root of where to install
IPDK_ROOT=ipdk-ebpf

usage() {
    echo ""
    echo "Usage:"
    echo "host_install.sh: -d"
    echo ""
    echo "  -d: Root location of where to build and install"
    echo ""
}

# Process commandline arguments
while getopts d: flag
do
    case "${flag}" in
        d)
            IPDK_ROOT="${OPTARG}"
            ;;
        *)
            usage
            exit
            ;;
    esac
done

#
# Clone, build and install p4 compiler
#

mkdir -p "${IPDK_ROOT}"
pushd "${IPDK_ROOT}" || exit

# Protobuf source code Repo checkout, Build and Install
if [ ! -d protobuf ] ; then
    git clone --depth=1 -b v3.18.1 https://github.com/google/protobuf.git
fi
pushd protobuf || exit
if [ ! -d build ] ; then
    mkdir -p build
    pushd build || exit
    cmake -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON "$CMAKE_PREFIX" ../cmake
    make -j4
    make install
    ldconfig
    popd || exit
fi
popd || exit

if [ ! -d p4c ] ; then
    git clone https://github.com/p4lang/p4c.git --recursive
fi
pushd p4c || exit
if [ ! -d build ] ; then
    python3 backends/ebpf/build_libbpf
    mkdir -p build && pushd build || exit
    cmake ..
    make -j4
    make install
    make clean
    ldconfig
    popd || exit
fi
popd || exit

#
# Clone, build and install psabpf
#
if [ ! -d psabpf ] ; then
    git clone https://github.com/P4-Research/psabpf.git --recursive
fi
pushd psabpf || exit
if [ ! -d build ] ; then
    ./build_libbpf.sh
    mkdir build && pushd build || exit
    cmake ..
    make -j4
    make install
    popd || exit
fi
popd || exit

#
# Clone, build and install psa-ebpf-demo
#
if [ ! -d psa-ebpf-demo ] ; then
    git clone https://github.com/P4-Research/psa-ebpf-demo.git
fi
# NOTE: For now, just clone

#
# Clone, build and install ipdk-docker-cnm
#

# NOTE: Old version of golang, upgrade this
if [ ! -f go1.11.13.linux-amd64.tar.gz ] ; then
    curl -OL https://golang.org/dl/go1.11.13.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.11.13.linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin
if [ ! -d ~/go/src/ipdk-plugin ] ; then
    mkdir -p ~/go/src
    pushd ~/go/src || exit
    git clone https://github.com/mestery/ipdk-plugin
    popd || exit
fi
pushd ~/go/src/ipdk-plugin || exit
go get
go build
popd || exit

# Final popd
popd || exit
