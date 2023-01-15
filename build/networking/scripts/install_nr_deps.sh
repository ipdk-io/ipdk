#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

usage() {
    echo ""
    echo "Usage:"
    echo "install_nr_deps.sh: -e|--extra-build-args [-n|--num-cores] -p|--prefix -s|--src-dir -h|--help"
    echo ""
    echo "  -e|--extra-build-args: Extra build arguments"
    echo "  -h|--help: Displays help"
    echo "  -n|--num-cores: Number of cores to be used for build"
    echo "  -p|--prefix: networking-recipe install path"
    echo "  -s|--src-dir: Networking-recipe source code path"
    echo ""
}

# Parse command-line options.
SHORTOPTS=e:,h,n:,p:,s:
LONGOPTS=extra-build-args:,help,num-cores:,prefix:,src-dir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
NR_SRC_DIR=""
NUM_CORES=4
INSTALL_PREFIX=""
EXTRA_BUILD_ARGS=""

# Process command-line options.
while true ; do
    case "${1}" in
    -e|--extra-build-args)
        EXTRA_BUILD_ARGS="${2}"
        shift 2 ;;
    -h|--help)
      usage
      exit 1 ;;
    -n|--num-cores)
        NUM_CORES="${2}"
        shift 2 ;;
    -p|--prefix)
        INSTALL_PREFIX="-DCMAKE_INSTALL_PREFIX=${2}"
        shift 2 ;;
    -s|--src-dir)
        NR_SRC_DIR="${2}"
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
echo "EXTRA_BUILD_ARGS: ${EXTRA_BUILD_ARGS}"
echo "NUM_CORES: ${NUM_CORES}"
echo "INSTALL_PREFIX: ${INSTALL_PREFIX}"
echo "NR_SRC_DIR: ${NR_SRC_DIR}"
echo ""

# Check for mandatory arguments
if [ -z "${NR_SRC_DIR}" ]; then
    echo "Networking-recipe source code path missing..."
    usage
    exit 1
fi

# Check source directory exists or not
if [ ! -d "${NR_SRC_DIR}" ]; then
    echo "Directory ${NR_SRC_DIR} doesn't exists..."
    exit 1
fi

# Build and install networking-recipe dependencies
pushd "${NR_SRC_DIR}"/setup || exit
cmake -B build "${INSTALL_PREFIX}" "${EXTRA_BUILD_ARGS}" || exit
cmake --build build -j"${NUM_CORES}" || exit
./cleanup.sh || exit
popd || exit
