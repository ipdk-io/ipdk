#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

current_script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
declare bridge
# shellcheck disable=SC1091
source "${current_script_dir}"/nat_variables.sh

ip link set "${bridge}" down
ip link delete "${bridge}" type bridge

kill -15 "$(cat "/var/run/qemu-dnsmasq-${bridge}.pid")"

