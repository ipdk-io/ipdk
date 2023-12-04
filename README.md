# IPDK

[![Makefile CI](https://github.com/ipdk-io/ipdk/actions/workflows/makefile.yml/badge.svg)](https://github.com/ipdk-io/ipdk/actions/workflows/makefile.yml)
[![Linters](https://github.com/ipdk-io/ipdk/actions/workflows/linters.yml/badge.svg)](https://github.com/ipdk-io/ipdk/actions/workflows/linters.yml)

Infrastructure Programmer Development Kit (IPDK) is an open source, vendor
agnostic framework of drivers and APIs for infrastructure offload and
management that runs on a CPU, IPU, DPU or switch. IPDK runs in Linux and uses
a set of well-established tools such as SPDK, DPDK and P4 to enable network
virtualization, storage virtualization, workload provisioning, root-of-trust
and offload capabilities found in the platform. IPDK provides a common platform
for increasing performance, optimizing resources and securing the
infrastructure as an open source community.

![IPDK Architecture](https://github.com/ipdk-io/ipdk-io.github.io/blob/main/img/ipdk-icons-white.png)

## Building and Using IPDK

Instructions for how to build IPDK are found under
[Networking Builds](build/README.md).
Storage-related work has been transitioned into OPI project - see
[RELEASENOTES for v23.07](RELEASENOTES.md).
