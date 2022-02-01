#!/usr/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

set -e
# shellcheck source=scripts/os_ver_details.sh
. os_ver_details.sh

if [ -z "$1" ]
then
   echo "Missing mandatory arguments:"
   echo "     Usage: ./build-p4c.sh <WORKDIR>"
   return 1
fi

#SHA on top which P4C is validated
P4C_SHA=d2f0c2a22286c6b6643e5e3906cf020d6d698c70

WORKDIR=$1
PATCH_DIR=/root/patches
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
#In protobuf version 3.18.1,'OK’ is no longer a member of
#‘google::protobuf::util::status_internal::Status’. Instead a
#public method (ok()) is available to check the return status.
#This patch applies necessary changes to P4C code to accomodate
#this change
git apply $PATCH_DIR/PATCH-01-P4C
mkdir build && cd build
cmake -DENABLE_BMV2=OFF \ -DENABLE_P4C_GRAPHS=OFF -DENABLE_P4TEST=OFF \
      -DENABLE_GTESTS=OFF ..
make $NUM_THREADS
make $NUM_THREADS install
make $NUM_THREADS clean
ldconfig

set +e
