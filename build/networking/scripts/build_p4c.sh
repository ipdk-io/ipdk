#!/usr/bin/bash
#Copyright (C) 2021-2022 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

set -e
# shellcheck source=networking/scripts/os_ver_details.sh
. os_ver_details.sh

if [ -z "$1" ]
then
   echo "Missing mandatory arguments:"
   echo "     Usage: ./build-p4c.sh <WORKDIR>"
   return 1
fi

#SHA on top which P4C is validated
P4C_SHA=bad00d940a7913d6df671dc4947409982d5f7a84

WORKDIR=$1
cd "$WORKDIR"

echo "Removing P4C directory if it already exits"
if [ -d "P4C" ]; then rm -Rf P4C; fi
echo "Cloning  P4C repo"
cd "$WORKDIR"

#Read the number of CPUs in a system and derive the NUM threads
get_num_cores
echo "Number of Parallel threads used: $NUM_THREADS ..."
echo ""

export PATH="$WORKDIR/p4ovs/P4OVS_DEPS_INSTALL/bin:$WORKDIR/p4ovs/P4OVS_DEPS_INSTALL/sbin:$PATH"
export LD_LIBRARY_PATH="$WORKDIR/p4ovs/P4OVS_DEPS_INSTALL/lib:$WORKDIR/p4ovs/P4OVS_DEPS_INSTALL/lib64:$LD_LIBRARY_PATH"

git clone https://github.com/p4lang/p4c.git P4C
cd P4C
git checkout $P4C_SHA
git submodule update --init --recursive
# Patch for supporting PNA indirect counters
# Currently changes are under PNA architecture review
# Patch will be removed once changes are official and
# available in open source p4lang/p4c
git apply "$WORKDIR/patches/ipdk_p4c_001.patch"
mkdir build && mkdir -p "$WORKDIR/p4c/install" && cd build

cmake -DCMAKE_INSTALL_PREFIX="$WORKDIR/p4c/install" \
  -DENABLE_BMV2=OFF \
  -DENABLE_EBPF=OFF \
  -DENABLE_UBPF=OFF \
  -DENABLE_GTESTS=OFF \
  -DENABLE_P4TEST=OFF \
  -DENABLE_P4C_GRAPHS=OFF \
  -DCMAKE_PREFIX_PATH="$WORKDIR/p4ovs/P4OVS_DEPS_INSTALL" \
  ..

make $NUM_THREADS
make $NUM_THREADS install
make $NUM_THREADS clean
ldconfig
rm -rf build

set +e
