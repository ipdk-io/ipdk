#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

function send_command_over_unix_socket() {
	socket="${1}"
	cmd="${2}"
	wait_for_secs="${3}"
	echo "${cmd}" | socat -T"${wait_for_secs}" -,ignoreeof unix-connect:"${socket}"
}

function send_command_over_unix_socket_and_no_word_found() {
	out=$( send_command_over_unix_socket "${1}" "${2}" "${3}" )

	searched_word="${4}"
	result=$(echo "${out}" | grep -i -c "${searched_word}")
	return "${result}"
}

function get_output_from_unix_socket() {
	socket="${1}"
	wait_for_secs="${2}"
	out=$( socat -T"${wait_for_secs}" -,ignoreeof unix-connect:"${socket}" )
	result=$?
	echo "${out}"
}
