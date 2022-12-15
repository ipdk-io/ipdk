#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
usage() {
    echo ""
    echo "Usage:"
    echo "install_nr_modules.sh: -w|--workdir [--scripts-dir] -h|--help"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  --scripts-dir: Directory path where all utility scripts copied.  [Default: ${WORKING_DIR}/scripts]"
    echo "  -w|--workdir: Working directory"
    echo ""
}

# Parse command-line options.
SHORTOPTS=h,w:
LONGOPTS=help,scripts-dir:,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"
# Set defaults.
WORKING_DIR=""
SCRIPTS_DIR=""
NUM_BUILD_CORES=4

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
      usage
      exit 1 ;;
    -w|--workdir)
        WORKING_DIR="${2}"
        shift 2 ;;
    --scripts-dir)
        SCRIPTS_DIR="${2}"
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
echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
echo ""

# Check mandatory arguments
if [ -z "${WORKING_DIR}" ]; then
    echo "Working directory missing.."
    usage
    exit 1
fi

# Setting SCRIPTS_DIR default path if not provided
if [ -z "${SCRIPTS_DIR}" ]; then
    SCRIPTS_DIR="${WORKING_DIR}"/scripts
    echo "Default SCRIPTS_DIR: ${SCRIPTS_DIR}"
fi

export PATH="${WORKING_DIR}"/scripts:"${PATH}"

NR_SRC_DIR="${WORKING_DIR}"/networking-recipe
DEPS_INSTALL_DIR="${WORKING_DIR}"/networking-recipe/deps_install
SDE_INSTALL_DIR="${WORKING_DIR}"/p4-sde/install

# Get number of cores to be used for build
. "${SCRIPTS_DIR}"/os_ver_details.sh
get_num_cores
if [ "${NUM_CORES}" -gt 4 ]; then
    NUM_BUILD_CORES="$((NUM_CORES / 4))"
fi

echo "Number of cores available on the system: ${NUM_CORES}"
echo "Number of cores used for build process: ${NUM_BUILD_CORES}"

# Download networking recipe source code
download_nr_src_code() {
    chmod +x "${SCRIPTS_DIR}"/download_nr_src_code.sh && \
        bash "${SCRIPTS_DIR}"/download_nr_src_code.sh --workdir="${WORKING_DIR}" || exit 1
}

# Build and install P4 SDE
install_p4sde() {
    chmod +x "${SCRIPTS_DIR}"/build_p4sde.sh && \
        bash "${SCRIPTS_DIR}"/build_p4sde.sh --workdir="${WORKING_DIR}" \
            --num-cores="${NUM_BUILD_CORES}" || exit 1
}

# Build and install P4 DPDK target compiler
install_p4c () {
    chmod +x "${SCRIPTS_DIR}"/build_p4c.sh && \
        bash "${SCRIPTS_DIR}"/build_p4c.sh --workdir="${WORKING_DIR}" \
            --deps-install-dir="${DEPS_INSTALL_DIR}" --num-cores="${NUM_BUILD_CORES}" || exit 1
}

# Build and install networking recipe dependencies
install_nr_deps() {
        chmod +x "${SCRIPTS_DIR}"/install_nr_deps.sh && \
        bash "${SCRIPTS_DIR}"/install_nr_deps.sh --src-dir="${NR_SRC_DIR}" \
            --prefix="${DEPS_INSTALL_DIR}" --num-cores="${NUM_BUILD_CORES}" || exit 1
}

# Build and install network recipe modules - infrap4d, gnmi, and p4ctl
install_nr() {
     chmod +x "${SCRIPTS_DIR}"/install_nr.sh && \
     bash "${SCRIPTS_DIR}"/install_nr.sh --src-dir="${NR_SRC_DIR}" \
         --deps-install-dir="${DEPS_INSTALL_DIR}" \
         --sde-install-dir="${SDE_INSTALL_DIR}" --num-cores="${NUM_BUILD_CORES}"
}

# Main
download_nr_src_code

if [ -z "${INSTALL_DEPENDENCIES}" ] || [ "${INSTALL_DEPENDENCIES}" == "y" ]
then
    install_p4sde
    install_nr_deps
    install_p4c
fi

install_nr
