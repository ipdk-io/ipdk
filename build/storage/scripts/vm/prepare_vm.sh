#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x
set -e

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/..

if [[ $# != 1 ]] ; then
    echo "Disk to boot vm file has to be specified"
    exit 1
fi

export LIBGUESTFS_BACKEND=direct

vm_file="${1}"
path_to_place_vm_file=$(dirname "$vm_file")

if [ ! -f "${vm_file}" ]; then
    vm_tmp_file="${path_to_place_vm_file}/vm_original.qcow2"
    wget -O "${vm_tmp_file}" https://download.fedoraproject.org/pub/fedora/linux/\
releases/33/Cloud/x86_64/images/Fedora-Cloud-Base-33-1.2.x86_64.qcow2
    virt-customize -a "${vm_tmp_file}" \
        --memsize 1260 \
        --root-password password:root \
        --install fio

    if [ "${WITHOUT_HOST_TARGET}" == "true" ]; then
        echo "Skip Host-Target container installation"
    else
        "${scripts_dir}"/build_container.sh host-target
        host_target_container="${path_to_place_vm_file}/host-target.tar"
        docker save -o "${host_target_container}" host-target
        run_customize=(virt-customize -a "${vm_tmp_file}")
        run_customize+=(--run-command 'dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo')
        run_customize+=(--run-command 'grubby --update-kernel ALL --args selinux=0')
        run_customize+=(--install "dnf-plugins-core,docker-ce,docker-ce-cli,containerd.io")
        run_customize+=(--copy-in "${path_to_place_vm_file}/host-target.tar:/")
        run_customize+=(--copy-in "${scripts_dir}/run_host_target_container.sh:/usr/local/bin")
        run_customize+=(--run-command 'systemctl enable docker.service')
        run_customize+=(--run-command 'service docker start')
        run_customize+=(--firstboot-command 'docker load --input /host-target.tar')
        run_customize+=(--firstboot-command 'rm -f /host-target.tar')
        "${run_customize[@]}"
        rm -f "${host_target_container}"
    fi
    mv "${vm_tmp_file}" "${vm_file}"
fi
