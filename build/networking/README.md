# IPDK Build

This directory contains the build instructions and scripts for IPDK. There are
three ways to build and run IPDK:

* [IPDK Container](README_DOCKER.md)
* [IPDK Native](README_NATIVE.md)
* [IPDK Vagrant](README_VAGRANT.md)

If you are comfortable with Docker and have it installed and working, you
should follow the [IPDK Container](README_DOCKER.md) build instructions.

If you want to experiment with IPDK running natively in a VM or on a bare-metal
host, you should follow the [IPDK Native](README_NATIVE.md) instructions.

If you want to experiment with IPDK running on a fresh Ubuntu 20.04 distribution,
then follow the [IPDK Vagrant](README_VAGRANT.md) build instructions and run an
IPDK container or natively inside the vagrant box.

## Security

IPDK uses underlying gRPC communication between clients (p4rt-ctl & gnmi-ctl)
and the server (`infrap4d`) for:

  - Creating ports
  - Setting up pipeline
  - Configuring forwarding rules

By default, this gRPC communication is secure. You have the option to use
insecure mode, if you wish. See the 
[security guide](https://github.com/ipdk-io/networking-recipe/blob/main/docs/guides/security-guide.md)
for more information.

IPDK includes a script (`generate-certs.sh`) to generate certificates and copy
them to a specific location that will be used by the gRPC Server and Client for
secure communication.

## Helpful references:

1. [Networking Recipe](https://github.com/ipdk-io/networking-recipe/blob/main/README.md)
2. [Networking Recipe Build Instructions](https://github.com/ipdk-io/networking-recipe/blob/main/docs/guides/dpdk-guide.md)
3. [P4RT-CTL P4runtime Client](https://github.com/ipdk-io/networking-recipe/blob/main/docs/clients/p4rt-ctl.rst)
4. [GNMI-CTL Port Configuration Client](https://github.com/ipdk-io/networking-recipe/blob/main/docs/clients/gnmi-ctl.rst)
5. [gRPC TLS Security](https://github.com/ipdk-io/networking-recipe/blob/main/docs/guides/security-guide.md)
6. [Sample P4 Program](https://github.com/ipdk-io/ipdk/blob/main/build/networking/examples/simple_l3/simple_l3.p4)
