#!/usr/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
set -e

usage() {
    echo ""
    echo "Usage:"
    echo "build_p4c.sh: -w|--workdir [-g|--git-sha] -d|--deps-install-dir [-n|--num-cores] -h|--help"
    echo ""
    echo "  -w|--workdir: Working directory"
    echo "  -g|--git-sha: GIT SHA to be used"
    echo "  -h|--help: Displays help"
    echo "  -n|--num-cores: Number of cores to be used for build"
    echo "  -d|--deps-install-dir: Networking-recipe dependencies instlattion folder"
    echo ""
}

# Parse command-line options.
SHORTOPTS=d:,g:,h,n:,w:
LONGOPTS=deps-install-dir:,git-sha:,help,num-cores:,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=""
DEPS_INSTALL_DIR=""
# Default release SHA
GIT_SHA="750e524a21537af676a2f2f281e78f660fd0d5c8"
NUM_CORES=4

# Process command-line options.
while true ; do
    case "${1}" in
    -d|--deps-install-dir)
        DEPS_INSTALL_DIR="${2}"
        shift 2 ;;
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
echo "DEPS_INSTALL_DIR: ${DEPS_INSTALL_DIR}"
echo "NUM_CORES: ${NUM_CORES}"
echo ""


# Check mandatory arguments passed or not
if [ -z "${WORKING_DIR}" ]; then
    echo "Working directory missing.."
    usage
    exit 1
fi

if [ -z "${DEPS_INSTALL_DIR}" ]; then
    echo "Networking-recipe dependencies instlattion folder missing.."
    usage
    exit 1
fi

cd "${WORKING_DIR}"

echo "Removing P4C directory if it already exits"
if [ -d "P4C" ]; then rm -Rf P4C; fi

export PATH="${DEPS_INSTALL_DIR}/bin:${DEPS_INSTALL_DIR}/sbin:$PATH"
export LD_LIBRARY_PATH="${DEPS_INSTALL_DIR}/lib:${DEPS_INSTALL_DIR}/lib64:$LD_LIBRARY_PATH"

git clone https://github.com/p4lang/p4c.git P4C
cd P4C
git checkout "${GIT_SHA}"
git submodule update --init --recursive
mkdir build && mkdir -p "${WORKING_DIR}"/p4c/install && cd build

cmake -DCMAKE_INSTALL_PREFIX="${WORKING_DIR}"/p4c/install \
  -DENABLE_BMV2=OFF \
  -DENABLE_EBPF=OFF \
  -DENABLE_UBPF=OFF \
  -DENABLE_GTESTS=OFF \
  -DENABLE_P4TEST=OFF \
  -DENABLE_P4C_GRAPHS=OFF \
  -DENABLE_PROTOBUF_STATIC=OFF \
  -DCMAKE_PREFIX_PATH="${DEPS_INSTALL_DIR}" \
  .. || exit 1

make -j"${NUM_CORES}" || exit 1
make -j"${NUM_CORES}" install || exit 1
make -j"${NUM_CORES}" clean || exit 1
ldconfig
rm -rf build

set +e
