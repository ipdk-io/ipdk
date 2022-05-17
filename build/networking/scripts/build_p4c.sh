#!/usr/bin/bash
#Copyright (C) 2021 Intel Corporation
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
P4C_SHA=45e5d70245ef8ec691d0d758e1c91a087ecdeb45

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

git clone https://github.com/p4lang/p4c.git --recursive P4C
cd P4C
git checkout $P4C_SHA
mkdir build && cd build
cmake  ..
make $NUM_THREADS
make $NUM_THREADS install
make $NUM_THREADS clean
ldconfig

set +e
