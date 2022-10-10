#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

SPDK_CONFIG_FILE="${SPDK_CONFIG_FILE:-}"
SPDK_IP_ADDR="${SPDK_IP_ADDR:-"0.0.0.0"}"
SPDK_PORT="${SPDK_PORT:-5260}"

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

function print_error_and_exit() {
    echo "${1}"
    exit 1
}

function check_all_variables_are_set() {
    number_re='^[0-9]+$'
    ip_addr_re='^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$'

    if [ -z "${SPDK_IP_ADDR}" ]; then
        print_error_and_exit "SPDK_IP_ADDR is not set"
    elif ! [[ "${SPDK_IP_ADDR}" =~ ${ip_addr_re} ]]; then
        print_error_and_exit "SPDK_IP_ADDR does not represent ip address"
    elif [ -z "${SPDK_PORT}" ]; then
        print_error_and_exit "SPDK_PORT is not set"
    elif ! [[ "${SPDK_PORT}" =~ ${number_re} ]] ; then
        print_error_and_exit "SPDK_PORT is not a number"
    fi
}

check_all_variables_are_set

export ALLOCATE_HUGEPAGES="true"
export IMAGE_NAME="storage-target"
ARGS=()
ARGS+=("-e" "SPDK_IP_ADDR=${SPDK_IP_ADDR}")
ARGS+=("-e" "SPDK_PORT=${SPDK_PORT}")
ARGS+=("-e" "SPDK_ARGS=${SPDK_ARGS}")

# shellcheck source=./scripts/run_container.sh
# shellcheck disable=SC1091,SC1090
source "${scripts_dir}/run_container.sh"
