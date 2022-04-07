#!/bin/bash
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Compile the P4 program example
pushd /root/ipdk-ebpf/p4c/backends/ebpf || exit
make -f ./runtime/kernel.mk BPFOBJ=/root/ipdk-ebpf/out.o P4FILE=/root/examples/simple_l3.p4 ARGS="-DPSA_PORT_RECIRCULATE=2" P4ARGS="--Wdisable=unused -I/usr/local/share/p4c/p4include/dpdk" psa
popd || exit
