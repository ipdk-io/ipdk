#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

set -e
[ "$DEBUG" == 'true' ] && set -x

current_script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
root_dir="${current_script_dir}"/../..
scripts_dir="${root_dir}"/scripts
# shellcheck disable=SC1091,SC1090
source "${scripts_dir}"/spdk_version.sh
bash "${scripts_dir}"/prepare_to_build.sh
declare https_proxy
declare http_proxy
declare no_proxy
export HTTPS_PROXY=${https_proxy}
export HTTP_PROXY=${http_proxy}
export NO_PROXY=${no_proxy}
spdk_version=$(get_spdk_version)
export SPDK_VERSION="${spdk_version}"
export DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}
export COMPOSE_DOCKER_CLI_BUILD=${COMPOSE_DOCKER_CLI_BUILD:-1}
host_target_image_tar="$current_script_dir/../../scripts/host-target.tar"

cleanup() {
    rm -f "$host_target_image_tar"
}
trap 'cleanup' EXIT

export NUMBER_OF_DEVICES_TO_ATTACH_IN_SCALE_OUT=\
"${NUMBER_OF_DEVICES_TO_ATTACH_IN_SCALE_OUT:-64}"

function run_test() {
    sudo_for_docker="sudo"
    is_user_docker_group_member=$(groups | grep docker &> /dev/null ; echo $?)
    if [ "${is_user_docker_group_member}" == "0" ]; then
        sudo_for_docker=
    elif [[ $(whoami) == "root" ]]; then
        sudo_for_docker=
    fi
    if [ "${DEBUG}" == 'true' ]; then
        export BUILDKIT_PROGRESS=plain
    fi

    export TEST_CASE_NAME="$1"
    ${sudo_for_docker} docker-compose \
        -f "${current_script_dir}/docker-compose.yml" \
        up \
        --build \
        --exit-code-from test-driver \
        --scale build_base=0
}

function provide_hugepages() {
    bash "${scripts_dir}"/allocate_hugepages.sh
}

function save_host_target_image_to_file() {
    local host_target_image_tar="$1"
    "${scripts_dir}"/build_container.sh "host-target"
    docker save -o "$host_target_image_tar" host-target
}

provide_hugepages
save_host_target_image_to_file "$host_target_image_tar"

test_cases=(hot-plug fio)
if [ "${BASE_TESTS_ONLY}" != "true" ]; then
    test_cases+=(scale-out)
fi

if [[ $# != 0 ]]; then
    run_test "${1}"
else
    for i in "${test_cases[@]}"; do
        run_test "${i}"
    done
fi
