#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

ROOT_DIR=$1
KEEP_SOURCE_CODE=$2
DEPLOYMENT_IMAGE=$3

FLAG_YES="YES"
FLAG_NO="NO"

echo "Copy p4ovs_env_setup.sh script from P4-OVS"
cp "${ROOT_DIR}/P4-OVS/p4ovs_env_setup.sh" "${ROOT_DIR}/scripts/"

echo "Copy configuration files"
mkdir -p "${ROOT_DIR}/configs"
cp "${ROOT_DIR}/P4-OVS/external/dpdk_port_config.pb.txt" "${ROOT_DIR}/configs"
cp "${ROOT_DIR}/P4-OVS/stratum/stratum/hal/bin/barefoot/tofino_skip_p4_no_bsp.conf" \
        "${ROOT_DIR}/configs"
# Create directory to keep source tar files
mkdir -p "${ROOT_DIR}/source_code"

if [ "${KEEP_SOURCE_CODE,,}" = "${FLAG_NO,,}" ] ; then
    echo "Copy build-p4ovs.sh script from P4-OVS"
    cp "${ROOT_DIR}/P4-OVS/build-p4ovs.sh" "${ROOT_DIR}/scripts/"

    echo "Copy install_dep_packages.sh script from P4-OVS"
    cp "${ROOT_DIR}/P4-OVS/install_dep_packages.sh" "${ROOT_DIR}/scripts/"

    echo "Removing P4-OVS source code"
    cd "${ROOT_DIR}" && rm -rf P4-OVS

    echo "Removing p4-driver source code"
    cd "${ROOT_DIR}/p4-sde" && rm -rf p4-driver

    echo "Removing P4C source code"
    cd "${ROOT_DIR}" &&  rm -rf P4C

elif [ "${KEEP_SOURCE_CODE,,}" = "${FLAG_YES,,}" ]; then
    echo "Make clean P4-OVS"
    cd "${ROOT_DIR}/P4-OVS" && make clean

    echo "Creating source tar files"
    tar -zcvf "${ROOT_DIR}/source_code/P4C.tgz" -C "${ROOT_DIR}" P4C
    tar -zcvf "${ROOT_DIR}/source_code/P4-OVS.tgz" -C "${ROOT_DIR}" P4-OVS
    tar -zcvf "${ROOT_DIR}/source_code/p4-sde.tgz" -C "${ROOT_DIR}" \
        --exclude="p4-sde/install" p4-sde
else
    echo "Unrecognized option for source code retention/removal: " \
        "${KEEP_SOURCE_CODE}"
fi

if [ "${DEPLOYMENT_IMAGE,,}" = "${FLAG_YES,,}" ]; then
    echo "Keeping modules and libraries needed for running stack"
    rm -rf "${ROOT_DIR}/p4ovs/P4OVS_DEPS_INSTALL/lib/"*.a
    rm -rf "${ROOT_DIR}/p4ovs/P4OVS_DEPS_INSTALL/lib64/"*.a
    rm -rf "${ROOT_DIR}/p4-sde/install/lib/python3.8"
    rm -rf "${ROOT_DIR}/p4-sde/install/lib/"*.a
    rm -rf "${ROOT_DIR}/p4-sde/install/bin/"dpdk-test*
    rm -rf "${ROOT_DIR}/p4-sde/install/lib64/"librte_*.a
    rm -rf "${ROOT_DIR}/p4c/"*

    if [ -d "${ROOT_DIR}/p4-sde/install/lib/x86_64-linux-gnu" ]; then
      rm -rf "${ROOT_DIR}/p4-sde/install/lib/x86_64-linux-gnu/"*.a
    fi
fi
