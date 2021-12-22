#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

ROOT_DIR=$1
KEEP_SOURCE_CODE=$2

FLAG_YES="YES"
FLAG_NO="NO"

echo "Removing P4OVS dependent modules source code"
cd "${ROOT_DIR}" &&  rm -rf P4OVS_DEPS_SRC_CODE

echo "Copy p4ovs_env_setup.sh script from P4-OVS"
cp "${ROOT_DIR}/P4-OVS/p4ovs_env_setup.sh" "${ROOT_DIR}/scripts/"

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

    # TODO
    # echo "Make clean p4-driver"
    # cd "${ROOT_DIR}/p4-sde/p4-driver" && make clean

    echo "Make clean P4C"
    cd "${ROOT_DIR}/P4C/build" && make clean

else
    echo "Unrecognized option for source code retention/removal: " \
        ${KEEP_SOURCE_CODE}
fi
