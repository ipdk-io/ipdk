#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/..

SHARED_VOLUME=${SHARED_VOLUME:-.}
DRIVE_TO_BOOT=${DRIVE_TO_BOOT:-${SHARED_VOLUME}/vm.qcow2}
qemu_serial="-serial stdio"
if [ -n "$UNIX_SERIAL" ]; then
  qemu_serial="-serial unix:${SHARED_VOLUME}/${UNIX_SERIAL},server,nowait"
fi

"${scripts_dir}"/vm/prepare_vm.sh "${DRIVE_TO_BOOT}"
"${scripts_dir}"/allocate_hugepages.sh

run_vm="sudo qemu-system-x86_64 \
  ${qemu_serial} \
  --enable-kvm \
  -cpu host \
  -m 1G -object memory-backend-file,id=mem0,size=1G,mem-path=/dev/hugepages,share=on -numa node,memdev=mem0 \
  -smp 2 \
  -drive file=${DRIVE_TO_BOOT},if=none,id=disk \
  -device ide-hd,drive=disk,bootindex=0 \
  -net nic -net tap,script=${scripts_dir}/vm/create_nat_for_vm.sh,\
downscript=${scripts_dir}/vm/delete_nat_for_vm.sh \
  -monitor unix:${SHARED_VOLUME}/vm_monitor,server,nowait \
  --nographic \
  $*"

$run_vm