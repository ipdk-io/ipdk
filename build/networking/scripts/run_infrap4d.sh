#! /bin/bash

# Copyright (C) 2021-2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e

usage() {
    echo ""
    echo "Usage:"
    echo "run_infrap4d.sh: --nr-install-dir --non-deamon-mode -h|--help"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  --nr-install-dir: Networking-recipe install path"
    echo "  --non-deamon-mode: Run infrap4d in non-deamon mode"
    echo ""
}

# Parse command-line options.
SHORTOPTS=h
LONGOPTS=help,nr-install-dir:,non-deamon-mode,

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
NR_INSTALL_DIR=""
DEAMON_MODE_ARGS=""

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
      usage
      exit 1 ;;
    --nr-install-dir)
        NR_INSTALL_DIR="${2}"
        shift 2 ;;
    --non-deamon-mode)
        DEAMON_MODE_ARGS="--nodetach"
        shift ;;
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
echo "NR_INSTALL_DIR: ${NR_INSTALL_DIR}"
echo "DEAMON_MODE_ARGS: ${DEAMON_MODE_ARGS}"
echo ""

if [ -z "${NR_INSTALL_DIR}" ]; then
    echo "Networking-recipe install path missing..."
    usage
    exit 1
fi

# Check source directory exists or not
if [ ! -d "${NR_INSTALL_DIR}" ]; then
    echo "Directory ${NR_INSTALL_DIR} doesn't exists..."
    exit 1
fi

# Run infrap4d module
"${NR_INSTALL_DIR}"/sbin/infrap4d "${DEAMON_MODE_ARGS}"
