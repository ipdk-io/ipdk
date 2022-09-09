#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x
set -e

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/..

if [ -z "$DRIVE_TO_BOOT" ] ; then
    echo "DRIVE_TO_BOOT file has to be specified"
    exit 1
fi

export LIBGUESTFS_BACKEND=direct

if [ ! -f "${DRIVE_TO_BOOT}" ] ; then
    if [ -z "$HOST_TARGET_SERVICE_PORT_IN_VM" ] ; then
        echo "HOST_TARGET_SERVICE_PORT_IN_VM value has to be specified"
        exit 1
    fi
    path_to_place_vm_file=$(dirname "$DRIVE_TO_BOOT")
    vm_tmp_file="${path_to_place_vm_file}/vm_original.qcow2"
    wget -O "${vm_tmp_file}" https://download.fedoraproject.org/pub/fedora/linux/\
releases/36/Cloud/x86_64/images/Fedora-Cloud-Base-36-1.5.x86_64.qcow2

    HOST_TARGET_TAR="${HOST_TARGET_TAR:-"${path_to_place_vm_file}/host-target.tar"}"
    host_target_tar_file_name=$(basename "${HOST_TARGET_TAR}")
    vm_host_target_tar_dir="/"
    vm_host_target_tar_path="${vm_host_target_tar_dir}${host_target_tar_file_name}"
    run_host_target_container_script="run_host_target_container.sh"
    run_container_script="run_container.sh"
    if [ ! -f "${HOST_TARGET_TAR}" ]; then
        host_target_container_name="host-target"
        "${scripts_dir}"/build_container.sh "$host_target_container_name"
        docker save -o "${HOST_TARGET_TAR}" "$host_target_container_name"
        trap 'rm -f ${HOST_TARGET_TAR}' EXIT
    fi

    systemd_host_target_service="/lib/systemd/system/host-target.service"
    run_customize=(virt-customize -a "${vm_tmp_file}")
    run_customize+=(--memsize 1260)
    run_customize+=(--root-password password:root)
    run_customize+=(--run-command 'dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo')
    run_customize+=(--run-command 'grubby --update-kernel ALL --args selinux=0')
    run_customize+=(--install "dnf-plugins-core,docker-ce,docker-ce-cli,containerd.io")
    run_customize+=(--copy-in "${HOST_TARGET_TAR}:${vm_host_target_tar_dir}")
    run_customize+=(--copy-in "${scripts_dir}/$run_host_target_container_script:/usr/local/bin")
    run_customize+=(--copy-in "${scripts_dir}/$run_container_script:/usr/local/bin")
    run_customize+=(--run-command 'systemctl enable docker.service')
    run_customize+=(--run-command 'service docker start')
    run_customize+=(--append-line "${systemd_host_target_service}:[Unit]")
    run_customize+=(--append-line "${systemd_host_target_service}:Description=Host-target service")
    run_customize+=(--append-line "${systemd_host_target_service}:After=docker.service")
    run_customize+=(--append-line "${systemd_host_target_service}:BindsTo=docker.service")
    run_customize+=(--append-line "${systemd_host_target_service}:[Service]")
    run_customize+=(--append-line "${systemd_host_target_service}:Environment='PORT=${HOST_TARGET_SERVICE_PORT_IN_VM}'")
    run_customize+=(--append-line "${systemd_host_target_service}:Environment='WITHOUT_TTY=true'")
    run_customize+=(--append-line "${systemd_host_target_service}:ExecStart=run_host_target_container.sh")
    run_customize+=(--append-line "${systemd_host_target_service}:ExecStop=docker container rm -f host-target")
    run_customize+=(--append-line "${systemd_host_target_service}:[Install]")
    run_customize+=(--append-line "${systemd_host_target_service}:WantedBy=multi-user.target")
    run_customize+=(--firstboot-command "docker load --input ${vm_host_target_tar_path}")
    run_customize+=(--firstboot-command "rm -f ${vm_host_target_tar_path}")
    run_customize+=(--firstboot-command 'systemctl start host-target')
    run_customize+=(--firstboot-command 'systemctl enable host-target')
    run_customize+=(--run-command "test -s $vm_host_target_tar_path")
    run_customize+=(--run-command "test -f /usr/local/bin/$run_host_target_container_script")
    run_customize+=(--run-command "test -f /usr/local/bin/$run_container_script")

    "${run_customize[@]}"
    mv "${vm_tmp_file}" "${DRIVE_TO_BOOT}"
elif [ -n "$HOST_TARGET_SERVICE_PORT_IN_VM" ] ; then
    # TODO: Modify port value in systemd host-target config file if the value in
    # HOST_TARGET_SERVICE_PORT_IN_VM is different
    echo "drive to boot vm already exists. If it is needed to change only port"
    echo "of host-target service within vm, then the vm file should be removed"
    echo "and rebuilt."
fi
