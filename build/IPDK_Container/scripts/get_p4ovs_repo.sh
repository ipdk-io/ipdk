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

#!/usr/bin/bash

if [ -z "$1" ]
then
   echo "-Missing mandatory arguments;"
   echo " - Usage: ./get_p4ovs_repo.sh <WORKDIR> "
   return 1
fi

WORKDIR=$1

cd $WORKDIR
echo "Removing P4-OVS directory if it already exits"
if [ -d "P4-OVS" ]; then rm -Rf P4-OVS; fi
echo "Cloning P4-OVS repo"
cd $WORKDIR
git clone https://github.com/ipdk-io/ovs.git -b ovs-with-p4 --recursive P4-OVS
