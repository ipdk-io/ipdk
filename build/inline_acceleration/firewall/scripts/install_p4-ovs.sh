#!/usr/bin/bash
#Copyright (C) 2022 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#Firewall-Inline-Aceleration v0.5

if [ -z "$1" ];
then
    echo "- Missing mandatory arguments:"
    echo " - Usage: ./install_p4-ovs.sh <WORKDIR>"
    return 1
fi

WORKDIR=$1
NETWORKING_DIR=../../../networking
SCRIPTS_DIR=/root/scripts

# remove already existing scripts directory
if [ -d ${SCRIPTS_DIR} ]; then rm -Rf ${SCRIPTS_DIR}; fi
# create /rrot/scripts directory to comply with build/networking/start_p4ovs.sh
mkdir -p ${SCRIPTS_DIR}

# copy scripts to /root/scripts folder to comply with build/networking/start_p4ovs.sh
cp ${NETWORKING_DIR}/scripts/get_p4ovs_repo.sh ${SCRIPTS_DIR}
cp ${NETWORKING_DIR}/scripts/build_p4sde.sh ${SCRIPTS_DIR}
cp ${NETWORKING_DIR}/scripts/build_p4c.sh  ${SCRIPTS_DIR}
cp ${NETWORKING_DIR}/scripts/os_ver_details.sh  ${SCRIPTS_DIR}
cp ${NETWORKING_DIR}/scripts/run_ovs.sh  ${SCRIPTS_DIR}

# Run the start_p4ovs.sh script to build the p4ovs
chmod +x ${NETWORKING_DIR}/start_p4ovs.sh && \
	bash ${NETWORKING_DIR}/start_p4ovs.sh "$WORKDIR"
