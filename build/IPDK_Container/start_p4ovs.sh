# Copyright (c) 2021 Intel Corporation.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

if [ -z "$1" ];
then
    echo "- Missing mandatory arguments:"
    echo " - Usage: ./start_p4ovs.sh <WORKDIR>"
    return 1
fi

#TODO: Temporary add
export http_proxy=child-fm.intel.com:911
export https_proxy=child-fm.intel.com:911

WORKDIR=$1
SCRIPTS_DIR=/root/scripts

export PATH="/root/scripts/:${PATH}"
export PATH="$WORKDIR/P4-OVS/:${PATH}"

get_p4ovs_repo() {
    chmod +x ${SCRIPTS_DIR}/get_p4ovs_repo.sh && sh get_p4ovs_repo.sh $WORKDIR
}

build_p4sde() {
    chmod +x ${SCRIPTS_DIR}/build_p4sde.sh && sh build_p4sde.sh $WORKDIR
}


install_dependencies() {
    cd $WORKDIR/P4-OVS && sed -i 's/sudo //g' install_dep_packages.sh && sh install_dep_packages.sh $WORKDIR
}

build_p4c () {
    chmod +x ${SCRIPTS_DIR}/build_p4c.sh && sh build_p4c.sh $WORKDIR
}

build_p4ovs () {
   cd $WORKDIR/P4-OVS && sh build-p4ovs.sh $WORKDIR/p4-sde/install
}

get_p4ovs_repo
build_p4sde
install_dependencies
build_p4c
build_p4ovs

echo "***** Next steps are in the run_ovs_cmds *****"
