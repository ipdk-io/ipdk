#! /bin/bash

# Copyright (C) 2021-2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e

usage() {
    echo ""
    echo "Usage:"
    echo "initialize_env.sh: --deps-install-dir --nr-install-dir --p4c-install-dir --sde-install-dir -h|--help"
    echo ""
    echo "  --deps-install-dir: Networking-recipe dependencies install path"
    echo "  -h|--help: Displays help"
    echo "  --nr-install-dir: Networking-recipe install path"
    echo "  --p4c-install-dir: P4C install path"
    echo "  --sde-install-dir: P4 SDE install path"
    echo ""
}

# Parse command-line options.
SHORTOPTS=h
LONGOPTS=deps-install-dir:,help,nr-install-dir:,sde-install-dir:,p4c-install-dir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
DEPS_INSTALL_DIR=""
SDE_INSTALL_DIR=""
NR_INSTALL_DIR=""
P4C_INSTALL_DIR=""

# Process command-line options.
while true ; do
    case "${1}" in
    --deps-install-dir)
        DEPS_INSTALL_DIR="${2}"
        shift 2 ;;
    -h|--help)
      usage
      exit 1 ;;
    --nr-install-dir)
        NR_INSTALL_DIR="${2}"
        shift 2 ;;
    --p4c-install-dir)
        P4C_INSTALL_DIR="${2}"
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
echo "DEPS_INSTALL_DIR: ${DEPS_INSTALL_DIR}"
echo "SDE_INSTALL_DIR: ${SDE_INSTALL_DIR}"
echo "NR_INSTALL_DIR: ${NR_INSTALL_DIR}"
echo "P4C_INSTALL_DIR: ${P4C_INSTALL_DIR}"
echo ""

if [ -z "${NR_INSTALL_DIR}" ]; then
    echo "Networking-recipe install path missing..."
    usage
    exit 1
fi

if [ -z "${DEPS_INSTALL_DIR}" ]; then
    echo "Networking-recipe dependencies install path missing..."
    usage
    exit 1
fi

if [ -z "${SDE_INSTALL_DIR}" ]; then
    echo "P4 SDE install path missing..."
    usage
    exit 1
fi

# Update SDE Install variable
export SDE_INSTALL="${SDE_INSTALL_DIR}"

# Update SDE libraries
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":"${SDE_INSTALL_DIR}"/lib
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":"${SDE_INSTALL_DIR}"/lib64
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":"${SDE_INSTALL_DIR}"/lib/x86_64-linux-gnu

# Update NETWORKING-RECIPE libraries
export LD_LIBRARY_PATH="${NR_INSTALL_DIR}"/lib:"${NR_INSTALL_DIR}"/lib64:"${LD_LIBRARY_PATH}"
export PATH="${NR_INSTALL_DIR}"/bin:"${NR_INSTALL_DIR}"/sbin:"${PATH}"

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":/usr/local/lib
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":/usr/local/lib64

# Update Dependent libraries
export LD_LIBRARY_PATH="${DEPS_INSTALL_DIR}"/lib:"${DEPS_INSTALL_DIR}"/lib64:"${LD_LIBRARY_PATH}"
export PATH="${DEPS_INSTALL_DIR}"/bin:"${DEPS_INSTALL_DIR}"/sbin:"${PATH}"
export LIBRARY_PATH="${DEPS_INSTALL_DIR}"/lib:"${DEPS_INSTALL_DIR}"/lib64:"${LIBRARY_PATH}"

if [ ! -z "${P4C_INSTALL_DIR}" ]; then
    export PATH="${P4C_INSTALL_DIR}"/bin:"${PATH}"
fi

echo ""
echo ""
echo "Updated Environment Variables ..."
echo "SDE_INSTALL_DIR: $SDE_INSTALL_DIR"
echo "LIBRARY_PATH: $LIBRARY_PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "PATH: $PATH"
echo ""

set +e
