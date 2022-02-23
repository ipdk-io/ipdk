#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

set -e

# shellcheck source=scripts/os_ver_details.sh
. os_ver_details.sh
get_os_ver_details

if [ -z "$1" ]
then
   echo "-Missing mandatory arguments:"
   echo " - Usage: ./build-p4sde.sh <WORKDIR> "
   return 1
fi

# npm using https for git
git config --global url."https://github.com/".insteadOf git@github.com:
git config --global url."https://".insteadOf git://

WORKDIR=$1
cd "${WORKDIR}" || exit

echo "Removing p4-sde directory if it already exists"
if [ -d "p4-sde" ]; then rm -Rf p4-sde; fi
mkdir "$1/p4-sde" && cd "$1/p4-sde" || exit
#..Setting Environment Variables..#
echo "Exporting Environment Variables....."
export SDE="${PWD}"
export SDE_INSTALL="$SDE/install"

#...Package Config Path...#
if [ "${OS}" = "Ubuntu" ]  || [ "${VER}" = "20.04" ] ; then
    arch=$(uname -m)
    export PKG_CONFIG_PATH=${SDE_INSTALL}/lib/${arch}-linux-gnu/pkgconfig
else
    export PKG_CONFIG_PATH=${SDE_INSTALL}/lib64/pkgconfig
fi

#..Runtime Path...#
export LD_LIBRARY_PATH=$SDE_INSTALL/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SDE_INSTALL/lib64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

echo "SDE environment variable"
echo "$SDE"
echo "$SDE_INSTALL"
echo "$PKG_CONFIG_PATH"

#Read the number of CPUs in a system and derive the NUM threads
get_num_cores
echo "Number of Parallel threads used: $NUM_THREADS ..."
echo ""

cd "$SDE" || exit
echo "Removing p4-driver repository if it already exists"
if [ -d "p4-driver" ]; then rm -Rf p4-driver; fi
echo "Compiling p4-driver"
#TODO: Below link needs to be updated when code is open-sourced
git clone https://github.com/p4lang/p4-dpdk-target.git --recursive p4-driver

pip3 install distro
cd p4-driver/tools/setup
if [ "${OS}" = "Ubuntu" ]; then
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
fi
python3 install_dep.py

cd "$SDE/p4-driver" || exit
./autogen.sh
./configure --prefix="$SDE_INSTALL"
make clean
make $NUM_THREADS
make $NUM_THREADS install
make $NUM_THREADS clean
ldconfig

set +e
