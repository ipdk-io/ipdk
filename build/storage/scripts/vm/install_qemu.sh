#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x
set -e

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
scripts_dir="$script_dir/.."
storage_dir="$scripts_dir/.."

# shellcheck disable=SC1091,SC1090
source "$script_dir/vm_default_variables.sh"

ipdk_dir="/tmp/ipdk/storage"
qemu_repo_dir="$ipdk_dir/qemu"
mkdir -p "$qemu_repo_dir"
function cleanup() {
    rm -rf "$qemu_repo_dir"
}
trap "cleanup" SIGINT SIGTERM EXIT

export GIT_REPOS="$qemu_repo_dir"
# shellcheck disable=SC1091,SC1090
source "$storage_dir/spdk/test/common/config/pkgdep/git"
qemu_install_dir="/usr/local/qemu/$VFIO_QEMU_BRANCH"

if [ -e "$QEMU_BINARY" ] ; then
    echo "QEMU is already installed, removing"
    sudo rm -f "$QEMU_BINARY"
    sudo rm -rf "$qemu_install_dir"
fi

_install_qemu "$GIT_REPO_QEMU_VFIO" "$VFIO_QEMU_BRANCH"
sudo ln -s "$qemu_install_dir/bin/qemu-system-x86_64" "$QEMU_BINARY"
