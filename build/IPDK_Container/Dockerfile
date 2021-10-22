#
# Copyright(c) 2021 Intel Corporation.
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
#
# Version 0.1.0

ARG OS_VERSION=${OS_VERSION}

FROM fedora:${OS_VERSION} AS base
LABEL maintainer="neha1.singh@intel.com"
ARG PROXY

# Installing dependent packages required for DPDK Build
RUN dnf -y update && \
  dnf -y groupinstall "Development Tools" "Development Libraries" && \
  dnf -y install meson && \
  dnf -y install cmake && \
  dnf -y install gdb && \
  dnf -y install libtool && \
  dnf -y install autoconf && \
  dnf -y install autoconf-archive && \
  dnf -y install automake && \
  dnf -y install scapy && \
  dnf -y install iproute && \
  dnf -y install net-tools && \
  dnf -y install gflags-devel && \
  dnf -y install iputils && \
  dnf -y install cctz && \
  dnf -y install json-devel && \
  dnf -y install python && \
  dnf -y install grpc-plugins && \
  dnf -y install python3-cffi && \
  dnf -y install libedit-devel && \
  dnf -y install expat-devel && \
  dnf -y install pip && \
  dnf -y install flex && \
  dnf -y install bison && \
  dnf -y install libgc-devel && \
  dnf -y install vim && \
  dnf -y clean all

# Installing all PYTHON packages
RUN python -m pip install --upgrade pip && \
    python -m pip install grpcio && \
    python -m pip install ovspy && \
    python -m pip install protobuf && \
    python -m pip install p4runtime && \
    pip3 install pyelftools

WORKDIR /root
COPY ./scripts scripts

FROM base AS p4-ovs-container
WORKDIR /root
COPY ./examples /root/examples
COPY ./start_p4ovs.sh /root/start_p4ovs.sh 
COPY ./run_ovs_cmds /root/run_ovs_cmds
ADD ./start_p4ovs.sh /root/start_p4ovs
ENTRYPOINT exec /root/start_p4ovs.sh /root
