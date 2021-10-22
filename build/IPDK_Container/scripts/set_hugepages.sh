#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

#!/usr/bin/bash

#...Setting Hugepages...#
mkdir /mnt/huge
mount -t hugetlbfs nodev /mnt/huge
echo -e "nodev /mnt/huge hugetlbfs\n" >> /etc/fstab

echo "vm.nr_hugepages = 4096" >> /etc/sysctl.conf
#sysctl -p /etc/sysctl.conf

echo 1024 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 1024 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages

