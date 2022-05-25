#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

# shellcheck disable=SC1091
source socket.sh

function attach_virtio_blk() {
	vm_monitor_socket=${1}
	vhost_socket=${2}
	id="${3}"
	num_queues=2
	error_word="error"

	echo "Attaching ${vhost_socket} to vm socket ${vm_monitor_socket}"
	add_chardev_cmd="chardev-add socket,id=${id},path=${vhost_socket}"
	if ! send_command_over_unix_socket_and_no_word_found \
			"${vm_monitor_socket}" "${add_chardev_cmd}" 1 "${error_word}" ; then
		return 1
	fi

	add_device_cmd="device_add vhost-user-blk-pci,chardev=${id},num-queues=${num_queues},id=${id}"
	if ! send_command_over_unix_socket_and_no_word_found \
			"${vm_monitor_socket}" "${add_device_cmd}" 1 "${error_word}" ; then
		return 1
	fi
	return 0
}

if [[ $# != 3 ]] ; then
	echo "Not all arguments are specified. <vm_monitor_socket> <vhost_socket> <device_id>"
	exit 1
fi

attach_virtio_blk "${1}" "${2}" "${3}"
exit $?
