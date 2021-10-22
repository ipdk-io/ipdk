#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

#!/usr/bin/bash

set -e
source os_ver_details.sh

if [ -z "$1" ]
then
   echo "Missing mandatory arguments:"
   echo "     Usage: ./build-p4c.sh <WORKDIR>"
   return 1
fi

WORKDIR=$1
cd $WORKDIR

echo "Removing P4C directory if it already exits"
if [ -d "P4C" ]; then rm -Rf P4C; fi
echo "Cloning  P4C repo"
cd $WORKDIR

#Read the number of CPUs in a system and derive the NUM threads
get_num_cores
echo "Number of Parallel threads used: $NUM_THREADS ..."
echo ""

git clone https://github.com/p4lang/p4c.git --recursive P4C
cd P4C
mkdir build && cd build
cmake ..
make $NUM_THREADS
make $NUM_THREADS install
ldconfig

set +e
