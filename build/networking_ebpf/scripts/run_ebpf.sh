#!/bin/bash
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Mount BPF filesystem
mount -t bpf bpf /sys/fs/bpf

# Compile the P4 program example
pushd /root/ipdk-ebpf/p4c/backends/ebpf || exit
make -f ./runtime/kernel.mk BPFOBJ=/root/ipdk-ebpf/simple_l3.o P4FILE=/root/examples/simple_l3.p4 ARGS="-DPSA_PORT_RECIRCULATE=2" P4ARGS="--Wdisable=unused -I/usr/local/share/p4c/p4include/dpdk" psa
make -f ./runtime/kernel.mk BPFOBJ=/root/ipdk-ebpf/demo.o P4FILE=/root/examples/demo.p4 ARGS="-DPSA_PORT_RECIRCULATE=2" P4ARGS="--Wdisable=unused -I/usr/local/share/p4c/p4include/dpdk" psa
popd || exit
