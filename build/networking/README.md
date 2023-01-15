# IPDK Build

This directory contains the build instructions and scripts for IPDK. There are
three ways to build and run IPDK:

* [IPDK Container](README_DOCKER.md)
* [IPDK Native](README_NATIVE.md)
* [IPDK Vagrant](README_VAGRANT.md)

If you are comfortable with Docker and have it installed and working, you
should follow the [IPDK Container](README_DOCKER.md) build instructions.  If
you want to experiment with IPDK running natively in either a VM or on a bare
metal host, you should follow the [IPDK Native](README_NATIVE.md) instructions.
If you want to experiment with IPDK running on a fresh ubuntu 20.04 distribution
then follow the [IPDK Vagrant](README_VAGRANT.md) build instructions and run an
IPDK container or native inside the vagrant box.

## Security

IPDK uses underlying gRPC communication between clients (p4rt-ctl & gnmi-ctl) and server
on InfraP4d for:
  - Creating ports.
  - Settingup pipeline.
  - Configuring forwarding rules.
By default this gRPC communication is secure, user has option to use in-secure mode too
refer [this](https://github.com/ipdk-io/networking-recipe/blob/main/docs/ipdk-security.md)
document.
IPDK has in-built script `generate-certs.sh` to generate certificates and copy to a specific
location which will be used by gRPC Server and Client for secure communication.


## Helpful references:

1. [Networking Recipe](https://github.com/ipdk-io/networking-recipe/blob/main/README.md)
2. [Networking Recipe Build Instructions](https://github.com/ipdk-io/networking-recipe/blob/main/docs/ipdk-dpdk.md)
3. [P4RT-CTL P4runtime Client](https://github.com/ipdk-io/networking-recipe/blob/main/docs/p4rt-ctl.rst)
4. [GNMI-CTL Port Configuration Client](https://github.com/ipdk-io/networking-recipe/blob/main/docs/dpdk/gnmi-ctl.rst)
5. [gRPC TLS Security](https://github.com/ipdk-io/networking-recipe/blob/main/docs/ipdk-security.md)
6. [Sample P4 Program](https://github.com/ipdk-io/ipdk/tree/conatiner_scripts/build/networking/examples/simple_l3)
