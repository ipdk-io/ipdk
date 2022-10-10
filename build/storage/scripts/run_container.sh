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

if [ "$DO_NOT_FETCH_OR_BUILD_IMAGE" == "true" ] ; then
    echo "Image will not be fetched from remote registry or built locally."
else
    if [ "$BUILD_IMAGE" != "true" ] ; then
        branch=$(git rev-parse --abbrev-ref HEAD)
        if [ "$branch" == "main" ] ; then
            echo "Image '$IMAGE_NAME' will be fetched from public registry."
            commit_sha_with_changes_in_storage=$(git log --format=format:%h -n 1 -- "$scripts_dir/..")
            arch=$(uname -m)
            fetch_image_name="ghcr.io/ipdk-io/storage/$IMAGE_NAME-kvm-$arch:sha-$commit_sha_with_changes_in_storage"
            if docker pull "$fetch_image_name" ; then
                IMAGE_NAME="$fetch_image_name"
            else
                echo "Failed to fetch '$IMAGE_NAME' image."
                BUILD_IMAGE="true"
            fi
        else
            echo "Pre-built image fetch is available only for main branch versions."
            BUILD_IMAGE="true"
        fi
    fi

    if [ "$BUILD_IMAGE" == "true" ] ; then
        echo "Building image '$IMAGE_NAME' locally."
        if bash "${scripts_dir}"/build_container.sh "$IMAGE_NAME" ; then
            echo "Image $IMAGE_NAME was built locally."
        else
            echo "Failed to build '$IMAGE_NAME' from local repo."
            exit 1
        fi
    fi
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
