#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

usage() {
    echo ""
    echo "Usage:"
    echo "post_build_cleanup.sh: -k|--keep-source-code -d|--deployment-image -w|--workdir -h|--help"
    echo ""
    echo "  -k|--keep-source-code: Keeps source code and available with final image"
    echo "  -d|--deployment-image: Minimizes the images size by removing unused modules. Ex: P4C, etc.."
    echo "  -h|--help: Displays help"
    echo "  -w|--workdir: Working directory"
    echo ""
}

# Parse command-line options.
SHORTOPTS=h,k:,d:,w:
LONGOPTS=deployment-image:,keep-source-code:,help,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=""
KEEP_SOURCE_CODE="NO"
DEPLOYMENT_IMAGE="NO"
FLAG_YES="YES"
FLAG_NO="NO"

# Process command-line options.
while true ; do
    case "${1}" in
    -w|--workdir)
        WORKING_DIR="${2}"
        shift 2 ;;
    -k|--keep-source-code)
        KEEP_SOURCE_CODE="${2}"
        shift 2 ;;
    -d|--deployment-image)
        DEPLOYMENT_IMAGE="${2}"
        shift 2 ;;
    -h|--help)
      usage
      exit 1 ;;
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
echo "KEEP_SOURCE_CODE: ${KEEP_SOURCE_CODE}"
echo "DEPLOYMENT_IMAGE: ${DEPLOYMENT_IMAGE}"
echo ""

if [ -z "${WORKING_DIR}" ]; then
    echo "Working directory missing.."
    usage
    exit 1
fi

# Create directory to keep source tar files
mkdir -p "${WORKING_DIR}/source_code"

if [ "${KEEP_SOURCE_CODE,,}" = "${FLAG_NO,,}" ] ; then
    echo "Removing networking-recipe source code"
    cd "${WORKING_DIR}" && mv -f networking-recipe/install . &&
    mv -f networking-recipe/deps_install . && mv -f networking-recipe/tools . &&
    rm -rf ./networking-recipe/* &&
    mv -f install ./networking-recipe/ && mv -f deps_install ./networking-recipe/ &&
    mv -f tools ./networking-recipe/

    echo "Removing p4-driver source code"
    cd "${WORKING_DIR}/p4-sde" && rm -rf p4-driver

    echo "Removing P4C source code"
    cd "${WORKING_DIR}" &&  rm -rf P4C

elif [ "${KEEP_SOURCE_CODE,,}" = "${FLAG_YES,,}" ]; then
    echo "Creating source tar files"
    tar -zcvf "${WORKING_DIR}/source_code/P4C.tgz" -C "${WORKING_DIR}" P4C
    tar -zcvf "${WORKING_DIR}/source_code/networking-recipe.tgz" -C "${WORKING_DIR}" \
        --exclude="networking-recipe/install" --exclude="networking-recipe/deps_install" \
        --exclude="networking-recipe/tools/tls" networking-recipe
    tar -zcvf "${WORKING_DIR}/source_code/p4-sde.tgz" -C "${WORKING_DIR}" \
        --exclude="p4-sde/install" p4-sde
else
    echo "Unrecognized option for source code retention/removal: " \
        "${KEEP_SOURCE_CODE}"
fi

if [ "${DEPLOYMENT_IMAGE,,}" = "${FLAG_YES,,}" ]; then
    echo "Keeping modules and libraries needed for running stack"
    rm -rf "${WORKING_DIR}/netwokring-recipe/install/lib/"*.a
    rm -rf "${WORKING_DIR}/netwokring-recipe/install/lib64/"*.a
    rm -rf "${WORKING_DIR}/p4-sde/install/lib/python3.10"
    rm -rf "${WORKING_DIR}/p4-sde/install/lib/"*.a
    rm -rf "${WORKING_DIR}/p4-sde/install/bin/"dpdk-test*
    rm -rf "${WORKING_DIR}/p4-sde/install/lib64/"librte_*.a
    rm -rf "${WORKING_DIR}/p4c/"*

    if [ -d "${WORKING_DIR}/p4-sde/install/lib/x86_64-linux-gnu" ]; then
      rm -rf "${WORKING_DIR}/p4-sde/install/lib/x86_64-linux-gnu/"*.a
    fi
fi
