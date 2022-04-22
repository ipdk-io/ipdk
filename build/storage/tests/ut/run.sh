#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
[ "$DEBUG" == 'true' ] && set -x
set -e

current_script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
root_dir="${current_script_dir}/../.."
scripts_dir="${root_dir}/scripts"
proxy_src_dir="${root_dir}/core/proxy-container"
host_target_src_dir="${root_dir}/core/host-target"

ut_container="ipdk-unit-tests"
"${scripts_dir}"/build_container.sh "${ut_container}"
args=(-e "DEBUG=${DEBUG}")
if [[ "${1}" == dev ]] ; then
    args+=(--entrypoint "/bin/bash")
    args+=(-v "${current_script_dir}/proxy-container:/proxy-container/tests")
    args+=(-v "${proxy_src_dir}:/proxy-container/src")
    args+=(-v "${current_script_dir}/host-target:/host-target/tests")
    args+=(-v "${host_target_src_dir}:/host-target/src")
fi
docker run -it "${args[@]}" "${ut_container}"
