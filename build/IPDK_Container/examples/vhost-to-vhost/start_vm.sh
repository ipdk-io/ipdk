#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

#QCOW2 IMAGES PATH...#
QCOW2_IMAG_PATH_VM1=<IMAGE1>.img
QCOW2_IMAG_PATH_VM2=<IMAGE2>.img

# application to run the Qemu KVM in Fedora.
QEMU=qemu-kvm
#enable below line if using Ubuntu
#QEMU=qemu-system-x86_64

${QEMU} -smp 4 -m 4096M \
    -boot c -cpu host -enable-kvm -nographic \
    -L /root/pc-bios -name VM1_TAP_DEV \
    -hda "${QCOW2_IMAG_PATH_VM1}" \
    -object memory-backend-file,id=mem,size=4096M,mem-path=/dev/hugepages,share=on \
    -mem-prealloc \
    -numa node,memdev=mem \
    -chardev socket,id=char1,path=/tmp/vhost-user-0 \
    -netdev type=vhost-user,id=netdev0,chardev=char1,vhostforce \
    -device virtio-net-pci,mac=00:e8:ca:11:aa:01,netdev=netdev0 \
    -serial telnet::6551,server,nowait &

${QEMU} -smp 4 -m 4096M \
    -boot c -cpu host -enable-kvm -nographic \
    -L /root/pc-bios -name VM1_TAP_DEV \
    -hda "${QCOW2_IMAG_PATH_VM2}" \
    -object memory-backend-file,id=mem,size=4096M,mem-path=/dev/hugepages,share=on \
    -mem-prealloc \
    -numa node,memdev=mem \
    -chardev socket,id=char2,path=/tmp/vhost-user-1 \
    -netdev type=vhost-user,id=netdev1,chardev=char2,vhostforce \
    -device virtio-net-pci,mac=00:e8:ca:11:bb:01,netdev=netdev1 \
    -serial telnet::6552,server,nowait &
sleep 3
