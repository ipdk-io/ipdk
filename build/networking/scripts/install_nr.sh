#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

usage() {
    echo ""
    echo "Usage:"
    echo "install_nr.sh: --deps-install-dir -e|--extra-build-args [-n|--num-cores] -p|--prefix -s|--src-dir --sde-install-dir -h|--help"
    echo ""
    echo "  --deps-install-dir: Networking-recipe dependencies install path"
    echo "  -e|--extra-build-args: Extra build arguments"
    echo "  -h|--help: Displays help"
    echo "  -n|--num-cores: Number of cores to be used for build"
    echo "  -p|--prefix: InfraP4d install path"
    echo "  -s|--src-dir: Networking-recipe source code path"
    echo "  --sde-install-dir: P4 SDE install path"
    echo ""
}

# Parse command-line options.
SHORTOPTS=e:,h,n:,p:,s:
LONGOPTS=deps-install-dir:,extra-build-args:,help,num-cores:,prefix:,src-dir:,sde-install-dir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
NUM_CORES=4
DEPEND_INSTALL_DIR=""
SDE_INSTALL_DIR=""
EXTRA_BUILD_ARGS=""
INSTALL_PREFIX=""
NR_SRC_DIR=""

# Process command-line options.
while true ; do
    case "${1}" in
    --deps-install-dir)
        DEPEND_INSTALL_DIR="${2}"
        shift 2 ;;
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
        INSTALL_PREFIX="--prefix=${2}"
        shift 2 ;;
    -s|--src-dir)
        NR_SRC_DIR="${2}"
        shift 2 ;;
    --sde-install-dir)
        SDE_INSTALL_DIR="${2}"
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
echo "DEPEND_INSTALL_DIR: ${DEPEND_INSTALL_DIR}"
echo "SDE_INSTALL_DIR: ${SDE_INSTALL_DIR}"
echo "EXTRA_BUILD_ARGS: ${EXTRA_BUILD_ARGS}"
echo "NUM_CORES: ${NUM_CORES}"
echo "INSTALL_PREFIX: ${INSTALL_PREFIX}"
echo "NR_SRC_DIR: ${NR_SRC_DIR}"
echo ""

if [ -z "${NR_SRC_DIR}" ]; then
    echo "Networking-recipe source code path missing..."
    usage
    exit 1
fi

if [ -z "${DEPEND_INSTALL_DIR}" ]; then
    echo "Networking-recipe dependencies install path missing..."
    usage
    exit 1
fi

if [ -z "${SDE_INSTALL_DIR}" ]; then
    echo "P4 SDE install path missing..."
    usage
    exit 1
fi

# Exporting all variables required for build and install
export SDE_INSTALL="${SDE_INSTALL_DIR}"
export DEPEND_INSTALL="${DEPEND_INSTALL_DIR}"
export INSTALL_PREFIX="${INSTALL_PREFIX}"
export LD_LIBRARY_PATH="${SDE_INSTALL_DIR}"/lib:"${SDE_INSTALL_DIR}"/lib64
export LD_LIBRARY_PATH="${DEPEND_INSTALL_DIR}"/lib:"${DEPEND_INSTALL_DIR}"/lib64:"${LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${SDE_INSTALL_DIR}"/lib/pkgconfig:"${SDE_INSTALL_DIR}"/lib64/pkgconfig:$PKG_CONFIG_PATH

# Build and install networking recipe modules
pushd "${NR_SRC_DIR}" || exit
./make-all.sh --target=dpdk "${INSTALL_PREFIX}" "${EXTRA_BUILD_ARGS}"
popd
