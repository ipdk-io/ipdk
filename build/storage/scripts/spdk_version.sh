#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

function get_spdk_version() {
    local script_dir root_dir spdk_dir spdk_version
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    root_dir=${script_dir}/..
    spdk_dir="${root_dir}/spdk"
    spdk_version=$(git -C "${spdk_dir}" describe --tags --abbrev=0)
    echo "${spdk_version%%-*}"
}
