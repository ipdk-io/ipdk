#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

declare https_proxy
declare http_proxy
declare no_proxy

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

if [[ -n "${SPDK_CONFIG_FILE}" ]] ; then
    SPDK_CONFIG_FILE=$(realpath "${SPDK_CONFIG_FILE}")
    ARGS+=("-v" "${SPDK_CONFIG_FILE}:/config")
fi

if [ "$ALLOCATE_HUGEPAGES" == "true" ] ; then
    bash "${scripts_dir}"/allocate_hugepages.sh
    ARGS+=("-v" "/dev/hugepages:/dev/hugepages")
fi

if [ "$BUILD_IMAGE" == "true" ] ; then
    bash "${scripts_dir}"/build_container.sh "$IMAGE_NAME"
fi

if [ "$AS_DAEMON" == "true" ] ; then
    ARGS+=("-d")
fi

if [ "$WITHOUT_TTY" != "true" ] ; then
    ARGS+=("-t")
fi

docker run \
    -i \
    --privileged \
    "${ARGS[@]}" \
    -e DEBUG="$DEBUG" \
    -e HTTPS_PROXY="$https_proxy" \
    -e HTTP_PROXY="$http_proxy" \
    -e NO_PROXY="$no_proxy" \
    --network host \
    "$IMAGE_NAME"
