#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# shellcheck disable=SC1091
source "$scripts_dir/vm/vm_default_variables.sh"

function create_sma_config_file() {
    local tmp_sma_config_file
    tmp_sma_config_file=$(mktemp /tmp/ipdk_sma_config_XXXXXX)
    local sock_path="${1}"
    local qmp_addr="${2}"
    local qmp_port="${3}"
    local sma_addr="${4}"
    local sma_port="${5}"

    cat << EOF >> "$tmp_sma_config_file"
address: $sma_addr
port: $sma_port
devices:
- name: vhost_blk
  params:
    qmp_addr: $qmp_addr
    qmp_port: $qmp_port
    sock_path: $sock_path
    buses:
    - name: '$IPDK_PCI_BRIDGE_0'
    - name: '$IPDK_PCI_BRIDGE_1'
EOF
    echo "$tmp_sma_config_file"
}
