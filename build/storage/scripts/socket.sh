#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

function send_command_over_unix_socket() {
	python <<- EOF
from scripts import socket_functions

print(
    socket_functions.send_command_over_unix_socket(
        sock="${1}",
        cmd="${2}",
        wait_for_secs=float("${3}")
    )
)
EOF
}

function get_output_from_unix_socket() {
	python <<- EOF
from scripts import socket_functions

print(
    socket_functions.get_output_from_unix_socket(
        sock="${1}",
        wait_for_secs=float("${2}")
    )
)
EOF
}
