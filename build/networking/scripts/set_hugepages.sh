#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

#...Setting Hugepages...#
mkdir -p /mnt/huge
if [ "$(mount | grep hugetlbfs)" == "" ]
then
	mount -t hugetlbfs nodev /mnt/huge
fi

if [ -e /etc/fstab ]; then
        if [ "$(grep huge < /etc/fstab)" == "" ]
        then
                echo -e "nodev /mnt/huge hugetlbfs\n" >> /etc/fstab
        fi
fi

# Get pagesize in MegaBytes, take only 1st result (head -1):
pagesizeM=$(grep hugetlbfs < /proc/mounts | head -1)
# Remove Prefix of = from: hugetlbfs /dev/hugepages hugetlbfs rw,relatime,pagesize=512M 0 0
pagesizeM=${pagesizeM#*=}
# Remove Suffix of M from: hugetlbfs /dev/hugepages hugetlbfs rw,relatime,pagesize=512M 0 0
pagesizeM=${pagesizeM%M*}

# 2 GB Total size
total_sizeM=2048
num_pages=$(( "$total_sizeM" / "$pagesizeM" ))
pagesizeKB=$(( "$pagesizeM" * 1024 ))

if [ "$(grep nr_hugepages < /etc/sysctl.conf)" == "" ]
then
        echo "vm.nr_hugepages = ${num_pages}" >> /etc/sysctl.conf
        #sysctl -p /etc/sysctl.conf
fi

#
# Check if the kernel/mm version of hugepages exists, and set hugepages if so.
#
if [ -d "/sys/kernel/mm/hugepages/hugepages-${pagesizeKB}kB" ] ; then
        echo "${num_pages}" | tee "/sys/kernel/mm/hugepages/hugepages-${pagesizeKB}kB/nr_hugepages"
fi

#
# Check if the node version of hugepages exists, and set hugepages if so.
#
if [ -d "/sys/devices/system/node/node0/hugepages/hugepages-${pagesizeKB}kB" ] ; then
        echo "${num_pages}" | sudo tee "/sys/devices/system/node/node0/hugepages/hugepages-${pagesizeKB}kB/nr_hugepages"
fi
if [ -d "/sys/devices/system/node/node1/hugepages/hugepages-${pagesizeKB}kB" ] ; then
        echo "${num_pages}" | sudo tee "/sys/devices/system/node/node1/hugepages/hugepages-${pagesizeKB}kB/nr_hugepages"
fi

