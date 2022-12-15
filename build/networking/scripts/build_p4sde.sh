#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
set -e

# shellcheck source=networking/scripts/os_ver_details.sh
. os_ver_details.sh
get_os_ver_details

usage() {
    echo ""
    echo "Usage:"
    echo "build_p4sde.sh: -w|--workdir [-g|--git-sha] [-n|--num-cores] -h|--help"
    echo ""
    echo "  -w|--workdir: Working directory"
    echo "  -g|--git-sha: GIT SHA to be used"
    echo "  -n|--num-cores: Number of cores to be used for build"
    echo "  -h|--help: Displays help"
    echo ""
}

# Parse command-line options.
SHORTOPTS=g:,h,-n:,w:
LONGOPTS=git-sha:,help,num-cores:,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=""
# Default release SHA
GIT_SHA="a43f8c90b9b51b32789ee59a07dd936ec4ce4849"
NUM_CORES=4
SDE_DIR_NAME="p4-sde"
SDE_SRC_DIR_NAME="p4-driver"

# Process command-line options.
while true ; do
    case "${1}" in
    -g|--git-sha)
        GIT_SHA="${2}"
        shift 2 ;;
    -h|--help)
        usage
        exit 1 ;;
    -n|--num-cores)
        NUM_CORES="${2}"
        shift 2 ;;
    -w|--workdir)
        WORKING_DIR="${2}"
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
echo "WORKING_DIR: ${WORKING_DIR}"
echo "GIT_SHA: ${GIT_SHA}"
echo "NUM_CORES: ${NUM_CORES}"
echo ""

# Check mandatory arguments passed or not
if [ -z "${WORKING_DIR}" ]; then
    echo "Working directory missing.."
    usage
    exit 1
fi

# npm using https for git
git config --global url."https://github.com/".insteadOf git@github.com:
git config --global url."https://".insteadOf git://

#...Setting Environment Variables...#
echo "Exporting Environment Variables....."
export SDE="${WORKING_DIR}/${SDE_DIR_NAME}"
export SDE_INSTALL="${SDE}/install"

#...Runtime Path...#
export LD_LIBRARY_PATH="${SDE_INSTALL}"/lib
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":"${SDE_INSTALL}"/lib64
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":/usr/local/lib64
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":/usr/local/lib

echo ""
echo "Environment variable"
echo "SDE: ${SDE}"
echo "SDE_INSTALL: ${SDE_INSTALL}"
echo "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
echo ""

#...Package Config Path...#
if [ "${OS}" = "Ubuntu" ]  || [ "${VER}" = "20.04" ] ; then
    export PKG_CONFIG_PATH="${SDE_INSTALL}"/lib/x86_64-linux-gnu/pkgconfig
else
    export PKG_CONFIG_PATH="${SDE_INSTALL}"/lib64/pkgconfig
fi

cd "${WORKING_DIR}" || exit 1

#...Remove if P4 SDE folder exists already...#
echo "Removing ${SDE_DIR_NAME} directory if it already exists"
if [ -d "${SDE_DIR_NAME}" ]; then
    rm -Rf "${SDE_DIR_NAME}"
fi

#...Creating SDE_INSTALL folder...#
mkdir -p "${SDE_INSTALL}" || exit 1

cd "${SDE}" || exit 1

echo "Removing ${SDE_SRC_DIR_NAME} repository if it already exists"
if [ -d "${SDE_SRC_DIR_NAME}" ]; then
    rm -Rf "${SDE_SRC_DIR_NAME}"
fi

git clone https://github.com/p4lang/p4-dpdk-target.git "${SDE_SRC_DIR_NAME}"
pushd "${SDE}/${SDE_SRC_DIR_NAME}"
git checkout "${GIT_SHA}"
git submodule update --init --recursive
popd

#...Install P4 SDE dependencies...#
pip3 install distro
pushd "${SDE}"/p4-driver/tools/setup
if [ "${OS}" = "Ubuntu" ]; then
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
fi
python3 install_dep.py
popd

#...Build and install P4 SDE modules...#
pushd "${SDE}"/p4-driver || exit 1
./autogen.sh
./configure --prefix="${SDE_INSTALL}" --with-generic-flags=yes
make clean
make -j"${NUM_CORES}"
make -j"${NUM_CORES}" install
make -j"${NUM_CORES}" clean
ldconfig
popd

set +e
