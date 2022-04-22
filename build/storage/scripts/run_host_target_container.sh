#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

declare https_proxy
declare http_proxy
declare no_proxy
IP_ADDR="${IP_ADDR:-"0.0.0.0"}"
PORT="${PORT:-50051}"

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

if [[ $(docker images --filter=reference='host-target' -q) == "" ]]; then
    bash "${scripts_dir}"/build_container.sh host-target
fi

docker_run="docker run \
    -it \
    --privileged \
    -e IP_ADDR=${IP_ADDR} \
    -e PORT=${PORT} \
    -e DEBUG=${DEBUG} \
    -e HTTPS_PROXY=${https_proxy} \
    -e HTTP_PROXY=${http_proxy} \
    -e NO_PROXY=${no_proxy} \
    --network host \
    -v /dev:/dev \
    host-target"
$docker_run


