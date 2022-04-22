#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#


[ "$DEBUG" == 'true' ] && set -x

declare https_proxy
declare http_proxy
declare no_proxy
SHARED_VOLUME=${SHARED_VOLUME:-$(realpath .)}
STORAGE_IP_ADDR="${STORAGE_IP_ADDR:-}"
STORAGE_PORT="${STORAGE_PORT:-4420}"
PROXY_IP_ADDR="${PROXY_IP_ADDR:-"0.0.0.0"}"
HOT_PLUG_SERVICE_PORT="${HOT_PLUG_SERVICE_PORT:-50051}"

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

function print_error_and_exit() {
    echo "${1}"
    exit 1
}

function check_all_variables_are_set() {
    number_re='^[0-9]+$'
    ip_addr_re='^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$'

    if [ -z "${SHARED_VOLUME}" ]; then
        print_error_and_exit "SHARED_VOLUME is not defined"
    elif [ ! -d "${SHARED_VOLUME}" ]; then
        print_error_and_exit "SHARED_VOLUME is not a directory"
    elif ! [[ "${STORAGE_PORT}" =~ ${number_re} ]] ; then
        print_error_and_exit "STORAGE_PORT is not a number"
    elif [ -z "${PROXY_IP_ADDR}" ]; then
        print_error_and_exit "PROXY_IP_ADDR is not set"
    elif ! [[ "${PROXY_IP_ADDR}" =~ ${ip_addr_re} ]]; then
        print_error_and_exit "PROXY_IP_ADDR does not represent ip address"
    elif [ -z "${HOT_PLUG_SERVICE_PORT}" ]; then
        print_error_and_exit "PORT is not set"
    elif ! [[ "${HOT_PLUG_SERVICE_PORT}" =~ ${number_re} ]] ; then
        print_error_and_exit "PORT is not a number"
    fi
}

check_all_variables_are_set
SHARED_VOLUME=$(realpath "${SHARED_VOLUME}")

bash "${scripts_dir}"/build_container.sh proxy-container
bash "${scripts_dir}"/allocate_hugepages.sh 2048

config_file_option=
if [[ -n "${SPDK_CONFIG_FILE}" ]]; then
    SPDK_CONFIG_FILE=$(realpath "${SPDK_CONFIG_FILE}")
    config_file_option="-v ${SPDK_CONFIG_FILE}:/config"
fi

docker_run="docker run \
    -it \
    --privileged \
    -v /dev/hugepages:/dev/hugepages \
    -v ${SHARED_VOLUME}:/ipdk-shared \
    ${config_file_option} \
    -e IP_ADDR=${STORAGE_IP_ADDR} \
    -e PORT=${STORAGE_PORT} \
    -e PROXY_IP_ADDR=${PROXY_IP_ADDR} \
    -e HOT_PLUG_SERVICE_PORT=${HOT_PLUG_SERVICE_PORT} \
    -e HOST_SHARED_VOLUME=${SHARED_VOLUME} \
    -e DEBUG=${DEBUG} \
    -e HTTPS_PROXY=${https_proxy} \
    -e HTTP_PROXY=${http_proxy} \
    -e NO_PROXY=${no_proxy} \
    --network host \
    proxy-container"
$docker_run
