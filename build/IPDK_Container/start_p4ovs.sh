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

# shellcheck source=scripts/os_ver_details.sh
. ${SCRIPTS_DIR}/os_ver_details.sh
get_os_ver_details

if [ "${OS}" = "Ubuntu" ]; then
    SHELL_STRING=""
else
    SHELL_STRING="sh"
fi

echo "SHELL_STRING=$SHELL_STRING"

get_p4ovs_repo() {
    chmod +x ${SCRIPTS_DIR}/get_p4ovs_repo.sh && \
        ${SHELL_STRING} ${SCRIPTS_DIR}/get_p4ovs_repo.sh "$WORKDIR"
}

build_p4sde() {
    chmod +x ${SCRIPTS_DIR}/build_p4sde.sh && \
        ${SHELL_STRING} ${SCRIPTS_DIR}/build_p4sde.sh "$WORKDIR"
}

install_dependencies() {
    if [ "${OS}" = "Ubuntu" ]; then
        cd "$WORKDIR"/P4-OVS && sed -i 's/sudo //g' install_dep_packages.sh && \
            sed -i s/v3.6.1/v3.7.1/g install_dep_packages.sh && \
            sed -i s/v1.17.2/v1.27.1/g install_dep_packages.sh && \
            ./install_dep_packages.sh "$WORKDIR"
    else
        cd "$WORKDIR"/P4-OVS && sed -i 's/sudo //g' install_dep_packages.sh && \
            ${SHELL_STRING} ./install_dep_packages.sh "$WORKDIR"
    fi
}

build_p4c () {
    chmod +x ${SCRIPTS_DIR}/build_p4c.sh && \
        ${SHELL_STRING} ${SCRIPTS_DIR}/build_p4c.sh "$WORKDIR"
}

build_p4ovs () {
   cd "$WORKDIR"/P4-OVS && ${SHELL_STRING} ./build-p4ovs.sh "$WORKDIR"/p4-sde/install
}

get_p4ovs_repo
build_p4sde
install_dependencies
build_p4c
build_p4ovs
