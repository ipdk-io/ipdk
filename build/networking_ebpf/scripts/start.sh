#!/bin/bash
# Copyright (C) 2021 Sander Tolsma
# SPDX-License-Identifier: Apache-2.0

# Initialize the IPDK container environment
initialize_env() {
	# NOOP for now
	echo ""
}

# run P4 ovs-vswitchd and ovsdb-server and wait
rundaemon() {
	echo "Start as long running process."
	initialize_env
	/root/scripts/run_ebpf.sh
	# TODO() Following doesn't work :-(
	# PIDFile="/var/run/openvswitch/ovs-vswitchd.pid"
	# wait $(<"$PIDFile")
	#
	# Or can we use:
	# wait "$(pidof ovs-vswitchd)"
	#
	# So try sleep infinity in the meantime
	sleep infinity
	echo "P4-eBPF stopped!"
}

# start to commandline
startcmd() {
	# shellcheck source=/dev/null
	. "$HOME/.bashrc"
	initialize_env
}

# execute command given through the arguments
execute() {
	# shellcheck source=/dev/null
	. "$HOME/.bashrc"
	initialize_env
	"${@}"
}

# This script enables the container to different actiona at invocation time
# Available commands are:
#   rundaemon - run P4OVS as a long running process
#   startcmd  - start with commandline
#   execute   - run a given commandline
#   help      - show help
command="startcmd"
if [[ "$1" != "" ]] ; then
	command="$1"
fi

case $command in
	rundaemon)
		rundaemon
		;;
	startcmd)
		startcmd
		;;
	execute)
		shift
		execute "${@}"
		;;
	*)
		echo "Unknown command $command"
		exit 1
		;;
esac
