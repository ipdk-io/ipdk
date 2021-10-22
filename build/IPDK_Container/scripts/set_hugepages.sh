# Copyright (c) 2021 Intel Corporation.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/usr/bin/bash

#...Setting Hugepages...#
mkdir /mnt/huge
mount -t hugetlbfs nodev /mnt/huge
echo -e "nodev /mnt/huge hugetlbfs\n" >> /etc/fstab

echo "vm.nr_hugepages = 4096" >> /etc/sysctl.conf
#sysctl -p /etc/sysctl.conf

echo 1024 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 1024 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages

