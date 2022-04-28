#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#


[ "$DEBUG" == 'true' ] && set -x

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# shellcheck disable=SC1091
source "$scripts_dir/vm/vm_default_variables.sh"
# shellcheck disable=SC1091
source "$scripts_dir/sma_config_file.sh"

declare https_proxy
declare http_proxy
declare no_proxy
SHARED_VOLUME=${SHARED_VOLUME:-$(realpath .)}
QMP_IP_ADDR="${QMP_IP_ADDR:-${DEFAULT_QMP_ADDRESS}}"
QMP_PORT="${QMP_PORT:-"$DEFAULT_QMP_PORT"}"
SMA_ADDR="${SMA_ADDR:-"0.0.0.0"}"
SMA_PORT="${SMA_PORT:-8080}"
HOT_PLUG_SERVICE_IP_ADDR="${HOT_PLUG_SERVICE_IP_ADDR:-"0.0.0.0"}"
HOT_PLUG_SERVICE_PORT="${HOT_PLUG_SERVICE_PORT:-50051}"


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
    elif [ -z "${HOT_PLUG_SERVICE_IP_ADDR}" ]; then
        print_error_and_exit "HOT_PLUG_SERVICE_IP_ADDR is not set"
    elif ! [[ "${HOT_PLUG_SERVICE_IP_ADDR}" =~ ${ip_addr_re} ]]; then
        print_error_and_exit "HOT_PLUG_SERVICE_IP_ADDR does not represent ip address"
    elif [ -z "${HOT_PLUG_SERVICE_PORT}" ]; then
        print_error_and_exit "PORT is not set"
    elif ! [[ "${HOT_PLUG_SERVICE_PORT}" =~ ${number_re} ]] ; then
        print_error_and_exit "PORT is not a number"
    elif ! [[ "${QMP_PORT}" =~ ${number_re} ]] ; then
        print_error_and_exit "QMP_PORT is not a number"
    elif [ -z "${QMP_IP_ADDR}" ]; then
        print_error_and_exit "QMP_IP_ADDR is not set"
    elif ! [[ "${QMP_IP_ADDR}" =~ ${ip_addr_re} ]]; then
        print_error_and_exit "QMP_IP_ADDR does not represent ip address"
    elif [ -z "${SMA_ADDR}" ]; then
        print_error_and_exit "SMA_ADDR is not set"
    elif ! [[ "${SMA_ADDR}" =~ ${ip_addr_re} ]]; then
        print_error_and_exit "SMA_ADDR does not represent ip address"
    elif ! [[ "${SMA_PORT}" =~ ${number_re} ]] ; then
        print_error_and_exit "SMA_PORT is not a number"
    fi
}

check_all_variables_are_set
SHARED_VOLUME=$(realpath "${SHARED_VOLUME}")

tmp_sma_config_file=$(create_sma_config_file "$SHARED_VOLUME" "$QMP_IP_ADDR" \
                        "$QMP_PORT" "$SMA_ADDR" "$SMA_PORT")
function cleanup() {
	rm -f "$tmp_sma_config_file"
}
trap 'cleanup' EXIT

bash "${scripts_dir}"/build_container.sh proxy-container
bash "${scripts_dir}"/allocate_hugepages.sh

spdk_config_file_option=
if [[ -n "${SPDK_CONFIG_FILE}" ]]; then
    SPDK_CONFIG_FILE=$(realpath "${SPDK_CONFIG_FILE}")
    spdk_config_file_option="-v ${SPDK_CONFIG_FILE}:/config"
fi

docker_run="docker run \
    -it \
    --privileged \
    -v /dev/hugepages:/dev/hugepages \
    -v ${SHARED_VOLUME}:/${SHARED_VOLUME} \
    -v ${tmp_sma_config_file}:/sma_config.yml \
    ${spdk_config_file_option} \
    -e HOT_PLUG_SERVICE_IP_ADDR=${HOT_PLUG_SERVICE_IP_ADDR} \
    -e HOT_PLUG_SERVICE_PORT=${HOT_PLUG_SERVICE_PORT} \
    -e HOST_SHARED_VOLUME=${SHARED_VOLUME} \
    -e DEBUG=${DEBUG} \
    -e HTTPS_PROXY=${https_proxy} \
    -e HTTP_PROXY=${http_proxy} \
    -e NO_PROXY=${no_proxy} \
    --network host \
    proxy-container"
$docker_run
