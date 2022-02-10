#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

if [ -z "$1" ];
then
    echo "- Missing mandatory arguments:"
    echo " - Usage: ./start_p4ovs.sh <WORKDIR>"
    return 1
fi

#export http_proxy=<your proxy>
#export https_proxy=<your proxy>

WORKDIR=$1
SCRIPTS_DIR=/root/scripts

export PATH="/root/scripts/:${PATH}"
export PATH="$WORKDIR/P4-OVS/:${PATH}"

get_p4ovs_repo() {
    chmod +x ${SCRIPTS_DIR}/get_p4ovs_repo.sh && \
        bash ${SCRIPTS_DIR}/get_p4ovs_repo.sh "$WORKDIR"
}

build_p4sde() {
    chmod +x ${SCRIPTS_DIR}/build_p4sde.sh && \
        bash ${SCRIPTS_DIR}/build_p4sde.sh "$WORKDIR"
}

install_dependencies() {
    cd "$WORKDIR"/P4-OVS && sed -i 's/sudo //g' install_dep_packages.sh && \
        bash ./install_dep_packages.sh "$WORKDIR"
    #...Removing Dependencies Source Code After Successful Installation...#
    rm -rf "${WORKDIR}/P4OVS_DEPS_SRC_CODE" || exit 1
}

build_p4c () {
    chmod +x ${SCRIPTS_DIR}/build_p4c.sh && \
        bash ${SCRIPTS_DIR}/build_p4c.sh "$WORKDIR"
}

build_p4ovs () {
   cd "$WORKDIR"/P4-OVS && bash ./build-p4ovs.sh "$WORKDIR"/p4-sde/install
}

if [ -z "${INSTALL_DEPENDENCIES}" ] || [ "${INSTALL_DEPENDENCIES}" == "y" ]
then
    get_p4ovs_repo
    build_p4sde
    install_dependencies
    build_p4c
fi
build_p4ovs
