#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#
# Version 0.1.0

usage() {
    echo ""
    echo "Usage:"
    echo "host_install.sh: -d|--ipdk-base-dir -s|--skip-deps-install -p|--proxy -w|--workdir -h|--help"
    echo ""
    echo "  -d|--ipdk-base-dir: Base directory of source"
    echo "  -h|--help: Displays help"
    echo "  -p|--proxy: Proxy to use"
    echo "  -s|--skip-deps-install: Skip installing and building dependencies"
    echo "  -w|--workdir: Working directory. [Default: /root"
    echo ""
}

# Parse command-line options.
SHORTOPTS=d:,h,p:,s:w:
LONGOPTS=ipdk-base-dir:,help,proxy:,skip-deps-install:,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
INSTALL_DEPENDENCIES=y
IPDK_BASE_DIR=/git
SCRIPTS_DIR="/root/scripts"
WORKING_DIR="/root"

# Process command-line options.
while true ; do
    case "${1}" in
    -d|--ipdk-base-dir)
        IPDK_BASE_DIR="${2}"
        shift 2 ;;
    -h|--help)
      usage
      exit 1 ;;
    -p|--prorxy)
        http_proxy="${2}"
        https_proxy="${2}"
        export http_proxy
        export https_proxy
        shift 2 ;;
    -s|--skip-deps-install)
        INSTALL_DEPENDENCIES=n
        shift 2 ;;
    -w|--workdir)
        WORKING_DIR="${2}"
        SCRIPTS_DIR="${WORKING_DIR}/scripts"
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
echo "IPDK_BASE_DIR: ${IPDK_BASE_DIR}"
echo "INSTALL_DEPENDENCIES: ${INSTALL_DEPENDENCIES}"
echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
echo "WORKING_DIR: ${WORKING_DIR}"
echo ""

pushd "${WORKING_DIR}" || exit
cp -r "${IPDK_BASE_DIR}"/ipdk/build/networking/scripts .
cp -r "${IPDK_BASE_DIR}"/ipdk/build/networking/examples .
cp -r "${IPDK_BASE_DIR}"/ipdk/build/networking/patches .
cp "${IPDK_BASE_DIR}"/ipdk/build/networking/install_nr_modules.sh install_nr_modules.sh
cp "${IPDK_BASE_DIR}"/ipdk/build/networking/run_ovs_cmds run_ovs_cmds
popd

# shellcheck source=networking/scripts/os_ver_details.sh
source "${SCRIPTS_DIR}"/os_ver_details.sh
get_os_ver_details

export INSTALL_DEPENDENCIES

# Installing standarnd packages
"${SCRIPTS_DIR}"/distro_pkg_install.sh --install-dev-pkgs --scripts-dir="${SCRIPTS_DIR}"

export OS_VERSION=20.04
export IMAGE_NAME=ipdk/nr-ubuntu20.04
export REPO="${IPDK_BASE_DIR}"/ipdk
TAG="$(cd "${REPO}" && git rev-parse --short HEAD)"
export TAG

echo "$OS_VERSION"
echo "$IMAGE_NAME"
echo "$REPO"
echo "$TAG"

"${WORKING_DIR}"/scripts/install_cmake_3.20.2.sh
"${WORKING_DIR}"/install_nr_modules.sh --workdir="${WORKING_DIR}"

# Generate and install certificates required for TLS
COMMON_NAME=localhost "${WORKING_DIR}"/scripts/generate_tls_certs.sh --workdir="${WORKING_DIR}"
