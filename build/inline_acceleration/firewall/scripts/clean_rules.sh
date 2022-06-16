#!/usr/bin/bash
#Copyright (C) 2022 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#Firewall-Inline-Aceleration v0.5

# Modify the ip's address and port numbers according to rules set in the pipeline.
set -e
echo "Deleting Rules "
sleep 0.5
sudo ovs-p4ctl del-entry br0 ingress.fw_direction "headers.ipv4.daddr=200.200.200.2/24"
sudo ovs-p4ctl del-entry br0 ingress.firewall "headers.ipv4.saddr=100.100.100.1,headers.ipv4.daddr=200.200.200.2,headers.ipv4.proto=6,headers.tcp.sport=2000,headers.tcp.dport=3000"
sudo ovs-p4ctl del-entry br0 ingress.egress_default "istd.ingress_port=3"
echo "Adding default egress rule for disabled offload"
sleep 0.6
sudo ovs-p4ctl add-entry br0 ingress.egress_default "istd.ingress_port=3,action=ingress.carry_port2(2)"

set +e
