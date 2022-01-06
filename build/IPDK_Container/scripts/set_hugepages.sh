#!/usr/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

#...Setting Hugepages...#
mkdir -p /mnt/huge
mount -t hugetlbfs nodev /mnt/huge
echo -e "nodev /mnt/huge hugetlbfs\n" >> /etc/fstab

echo "vm.nr_hugepages = 4096" >> /etc/sysctl.conf
#sysctl -p /etc/sysctl.conf

#
# Check if the kernel/mm version of hugepages exists, and set hugepages if so.
#
if [ -d /sys/kernel/mm/hugepages/hugepages-2048kB ] ; then
	echo 1024 | tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
fi

#
# Check if the node version of hugepages exists, and set hugepages if so.
#
if [ -d /sys/devices/system/node/node0/hugepages/hugepages-2048kB ] ; then
	echo 1024 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
fi
if [ -d /sys/devices/system/node/node1/hugepages/hugepages-2048kB ] ; then
	echo 1024 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages
fi
