#! /bin/bash

# Copyright (C) 2021-2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e

usage() {
    echo ""
    echo "Usage:"
    echo "setup_nr_cfg_file.sh: --nr-install-dir --sde-install-dir -h|--help"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  --nr-install-dir: Networking-recipe install path"
    echo "  --sde-install-dir: P4 SDE install path"
    echo ""
}

# Parse command-line options.
SHORTOPTS=h
LONGOPTS=help,nr-install-dir:,sde-install-dir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
SDE_INSTALL_DIR=""
NR_INSTALL_DIR=""

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
      usage
      exit 1 ;;
    --nr-install-dir)
        NR_INSTALL_DIR="${2}"
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
echo "SDE_INSTALL_DIR: ${SDE_INSTALL_DIR}"
echo "NR_INSTALL_DIR: ${NR_INSTALL_DIR}"
echo ""

if [ -z "${NR_INSTALL_DIR}" ]; then
    echo "Networking-recipe install path missing..."
    usage
    exit 1
fi

if [ -z "${SDE_INSTALL_DIR}" ]; then
    echo "P4 SDE install path missing..."
    usage
    exit 1
fi

#... Create required directories and copy the config files ...#
# Create networking-recipe directories for configs/logs/runtime file..
mkdir -p /etc/stratum/
mkdir -p /var/log/stratum/
mkdir -p /usr/share/stratum/dpdk
mkdir -p /usr/share/target_sys/
cp "${NR_INSTALL_DIR}"/share/stratum/dpdk/dpdk_port_config.pb.txt /usr/share/stratum/dpdk/
cp "${NR_INSTALL_DIR}"/share/stratum/dpdk/dpdk_skip_p4.conf /usr/share/stratum/dpdk/
cp "${SDE_INSTALL_DIR}"/share/target_sys/zlog-cfg /usr/share/target_sys/

