#!/bin/bash
#set -o xtrace
set -e
if [[ "$1" == *"help"* ]]
then
    echo " - Usage: ./run_ovs.sh [P4OVS_DEPS_INSTALL]"
    echo " - [P4OVS_DEPS_INSTALL]: Optional parameter. Defines absolute path" \
         " where dependent packages are installed."
    exit 1
fi
if [ -z "$1" ]
then
    export RUN_OVS=/usr/local
else
    export RUN_OVS=$1
fi
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

if [ -d "$RUN_OVS/etc/openvswitch" ]; then
    echo "Remove previous configs from: $RUN_OVS/etc/openvswitch"
    rm -rf "$RUN_OVS/etc/openvswitch/conf.db"
    rm -rf "$RUN_OVS/etc/openvswitch/.conf.db*"
else
    echo "Create directory: $RUN_OVS/etc/openvswitch"
    mkdir -p "$RUN_OVS/etc/openvswitch"
fi

if [ -d "$RUN_OVS/var/run/openvswitch" ]; then
    echo "Remove previous configs from: $RUN_OVS/var/run/openvswitch"
    rm -rf "$RUN_OVS/var/run/openvswitch/*.pid"
    rm -rf "$RUN_OVS/var/run/openvswitch/*.ctl"
else
    echo "Create directory: $RUN_OVS/var/run/openvswitch"
    mkdir -p "$RUN_OVS/var/run/openvswitch"
fi

echo "Create an OVSDB with avaiable schema...."
ovsdb-tool create "$RUN_OVS/etc/openvswitch/conf.db" \
        "$RUN_OVS/share/openvswitch/vswitch.ovsschema"

echo "Starting OVSDB server...."
ovsdb-server \
        --remote=punix:"$RUN_OVS/var/run/openvswitch/db.sock" \
        --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
        --pidfile --detach

ovs-vsctl --no-wait init

echo "Staring OVS-VSWITCHD Process...."
GLOG_log_dir=/tmp/logs ovs-vswitchd --pidfile --detach --no-chdir unix:"$RUN_OVS/var/run/openvswitch/db.sock" --mlockall --log-file=/tmp/ovs-vswitchd.log

echo "All Processes Started....."
