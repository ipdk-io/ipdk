#!/bin/bash
#Copyright (C) 2021-2022 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

sudo apt -y remove cmake
sudo apt -y purge --auto-remove cmake
sudo apt-get -y purge cmake
sudo rm -rf /usr/local/bin/cmake || true
mkdir -p /root/cmake-3.20.2/
wget https://cmake.org/files/v3.20/cmake-3.20.2-linux-x86_64.sh -O /root/cmake-3.20.2/cmake-3.20.2-linux-x86_64.sh
chmod a+x /root/cmake-3.20.2/cmake-3.20.2-linux-x86_64.sh
sudo mkdir -p /opt/rh/cmake
cd /root/cmake-3.20.2/ && sudo sh cmake-3.20.2-linux-x86_64.sh --prefix=/opt/rh/cmake --skip-license
sudo ln -s /opt/rh/cmake/bin/cmake /usr/local/bin/cmake
