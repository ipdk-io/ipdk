#!/usr/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

#set -o xtrace

#Kill and delete any logs from previous run
echo "Killing OVS Processes If Already Running...."

set +o errexit
if [[ $(pidof ovsdb-server) ]]; then
        echo "Killing ovsdb-server process...."
	kill -9 "$(pidof ovsdb-server)"
fi

if [[ $(pidof ovs-vswitchd) ]]; then
        echo "Killing ovs-vswitchd process...."
	kill -9 "$(pidof ovs-vswitchd)"
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
