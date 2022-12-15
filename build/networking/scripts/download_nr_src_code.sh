#!/usr/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

usage() {
    echo ""
    echo "Usage:"
    echo "download_nr_src_code.sh: -w|--workdir -h|--help"
    echo ""
    echo "  -g|--git-sha: GIT SHA to be used"
    echo "  -w|--workdir: Working directory"
    echo "  -h|--help: Displays help"
    echo ""
}


# Parse command-line options.
SHORTOPTS=g:h,w:
LONGOPTS=help,git-sha:,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=""
GIT_SHA="3a18b11217629aee6c93d95b6df57c5fee6a005f"
NR_DIR="networking-recipe"

# Process command-line options.
while true ; do
    case "${1}" in
    -g|--git-sha)
        GIT_SHA="${2}"
        shift 2 ;;
    -h|--help)
      usage
      exit 1 ;;
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

# Check mandatory arguments passed or not
if [ -z "${WORKING_DIR}" ]; then
    echo "Working directory missing.."
    usage
    exit 1
fi

cd "${WORKING_DIR}" || exit

echo "Removing ${NR_DIR} directory if it already exits"
if [ -d "${NR_DIR}" ]; then
    rm -Rf "${NR_DIR}"
fi

echo "Downloading networking recipe source code..."
cd "${WORKING_DIR}" || exit
git clone https://github.com/ipdk-io/networking-recipe.git networking-recipe
pushd "${WORKING_DIR}/${NR_DIR}" || exit
git checkout "${GIT_SHA}"
git submodule update --init --recursive
popd || exit
