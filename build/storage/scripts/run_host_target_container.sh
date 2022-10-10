#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

IP_ADDR="${IP_ADDR:-"0.0.0.0"}"
PORT="${PORT:-50051}"
# Set this variable below if it is needed to attach/change
# customization at container start-up
CUSTOMIZATION_DIR="${CUSTOMIZATION_DIR:-}"

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

function print_error_and_exit() {
    echo "${1}"
    exit 1
}

function check_all_variables_are_set() {
    number_re='^[0-9]+$'
    ip_addr_re='^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$'

    if [ -z "${IP_ADDR}" ]; then
        print_error_and_exit "IP_ADDR is not set"
    elif ! [[ "${IP_ADDR}" =~ ${ip_addr_re} ]]; then
        print_error_and_exit "IP_ADDR does not represent ip address"
    elif [ -z "${PORT}" ]; then
        print_error_and_exit "PORT is not set"
    elif ! [[ "${PORT}" =~ ${number_re} ]] ; then
        print_error_and_exit "PORT is not a number"
    fi
}

check_all_variables_are_set

export IMAGE_NAME="host-target"

ARGS=()
ARGS+=("-v" "/dev:/dev")
ARGS+=("-e" "IP_ADDR=${IP_ADDR}")
ARGS+=("-e" "PORT=${PORT}")
if [[ -n "$CUSTOMIZATION_DIR" ]]; then
    customization_dir_in_container="/customizations"
    ARGS+=("-v" "$(realpath "$CUSTOMIZATION_DIR"):$customization_dir_in_container")
    ARGS+=("-e" "CUSTOMIZATION_DIR_IN_CONTAINER=$customization_dir_in_container")

    echo "Customization directoty is specified. Environment variable will be set to start a local build."
    export BUILD_IMAGE="true"
elif find "$scripts_dir/../core/host-target/customizations" -name '*.py' | grep '.py' ; then
    echo "Python files are found in host-target customizations dir. Environment variable will be set to start a local build. "
    export BUILD_IMAGE="true"
fi

# shellcheck source=./scripts/run_container.sh
# shellcheck disable=SC1091,SC1090
source "${scripts_dir}/run_container.sh"
