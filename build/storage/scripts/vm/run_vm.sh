#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/..

VM_DIR=${VM_DIR:-.}

bash "${scripts_dir}"/vm/prepare_vm.sh "${VM_DIR}"

run_vm="sudo qemu-system-x86_64 \
  --enable-kvm \
  -cpu host \
  -m 1G -object memory-backend-file,id=mem0,size=1G,mem-path=/dev/hugepages,share=on -numa node,memdev=mem0 \
  -smp 2 \
  -drive file=${VM_DIR}/vm.qcow2,if=none,id=disk \
  -device ide-hd,drive=disk,bootindex=0 \
  -net nic -net tap,script=${scripts_dir}/vm/create_nat_for_vm.sh,\
downscript=${scripts_dir}/vm/delete_nat_for_vm.sh \
  -monitor unix:${VM_DIR}/vm_monitor,server,nowait \
  --nographic"

$run_vm