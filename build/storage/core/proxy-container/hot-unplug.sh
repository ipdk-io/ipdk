#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

# shellcheck disable=SC1091
source socket.sh

function dettach_virtio_blk() {
	vm_monitor_socket=${1}
	id="${2}"
	error_word="error"

	echo "Dettaching ${id} from ${vm_monitor_socket}"
	device_del_cmd="device_del ${id}"
	if ! send_command_over_unix_socket_and_no_word_found \
			"${vm_monitor_socket}" "${device_del_cmd}" 1 "${error_word}" ; then
		return 1
	fi

	remove_chardev_cmd="chardev-remove ${id}"
	if ! send_command_over_unix_socket_and_no_word_found \
			"${vm_monitor_socket}" "${remove_chardev_cmd}" 1 "${error_word}" ; then
		return 1
	fi
	return 0
}

if [[ $# != 2 ]] ; then
	echo "Not all arguments are specified. <vm_monitor_socket> <device_id>"
	exit 1
fi

dettach_virtio_blk "${1}" "${2}"
exit $?
