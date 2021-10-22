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
#set -o xtrace

#Kill and delete any logs from previous run
echo "Killing OVS Processes If Already Running...."

set +o errexit
if [[ $(pidof ovsdb-server) ]]; then
        echo "Killing ovsdb-server process...."
        kill -9 `pidof ovsdb-server`
fi

if [[ $(pidof ovs-vswitchd) ]]; then
        echo "Killing ovs-vswitchd process...."
        kill -9 `pidof ovs-vswitchd`
fi
set -o errexit

echo "Creating /var/run/openvswitch"
mkdir -p /var/run/openvswitch

echo "Starting OvS DB server...."
rm -rf /usr/local/etc/openvswitch/conf.db
rm -rf /usr/local/etc/openvswitch/.conf.db*
rm -rf /usr/local/var/run/openvswitch/*.pid
rm -rf /usr/local/var/run/openvswitch/*.ctl

mkdir -p /usr/local/etc/openvswitch
mkdir -p /usr/local/var/run/openvswitch
ovsdb-tool create /usr/local/etc/openvswitch/conf.db \
        /usr/local/share/openvswitch/vswitch.ovsschema

ovsdb-server \
        --remote=punix:/usr/local/var/run/openvswitch/db.sock \
        --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
        --pidfile --detach

ovs-vsctl --no-wait init

echo "Staring OvS VSWITCHD Process...."
ovs-vswitchd --pidfile --detach --no-chdir --mlockall --log-file=/tmp/ovs-vswitchd.log
#ovs-vswitchd --pidfile --mlockall --log-file=/tmp/ovs-vswitchd.log

echo "All Processes Started....."
