#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x
set -e

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
root_dir="${script_dir}/.."
# shellcheck disable=SC1091,SC1090
source "${script_dir}"/spdk_version.sh
"${script_dir}"/prepare_to_build.sh

DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}

build_proxies="--build-arg HTTP_PROXY=${HTTP_PROXY} \
    --build-arg HTTPS_PROXY=${HTTPS_PROXY} \
    --build-arg NO_PROXY=${NO_PROXY}"
spdk_version_build_arg="--build-arg SPDK_VERSION=$(get_spdk_version)"

join_by() {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

container_to_build="${1}"

possible_containers=("storage-target" "ipu-storage-container" "ipdk-unit-tests" "host-target")
if [[ " ${possible_containers[*]} " =~ ${container_to_build} ]]; then
    export DOCKER_BUILDKIT="${DOCKER_BUILDKIT}"

    docker_build="docker build ${build_proxies} \
        ${spdk_version_build_arg} \
        -t ${container_to_build} --target ${container_to_build} ${root_dir}"
    $docker_build
else
    echo "Unknown container '${container_to_build}'"
    possible_containers_as_string=$(join_by ", " "${possible_containers[@]}")
    echo "Possible containers: ${possible_containers_as_string}"
    exit 1
fi

