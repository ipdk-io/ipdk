# IPDK Build Directory

This directory contains all of the individual IPDK recipes. These can all be
built using the `ipdk` CLI found here.

## Install IPDK CLI
To fully use all the features of IPDK container and if you want to follow the
examples, then install the IPDK CLI with the following command executed from
the directory this README is found in:

```
./ipdk install
```

If your system has not added `~/.local/bin` or `~/bin` to your search PATH then
execute the given `export PATH=<>` command to add the `ipdk` command
to your current environment path each time you open a new terminal to your
system!

The IPDK CLI is by default setup for a `Fedora:33` environment. Build
and run your IPDK container with the `ubuntu:20.04` or `ubuntu:18.04` base
environment by running `ipdk install ubuntu2004` or `ipdk install ubuntu1804`.
`ipdk install default` will bring you back to the default environment (fedora)

## Build Containers

The following are the container images you can build from here:

* Fedora 33 P4-DPDK networking container: `ipdk install fedora33`
* Ubuntu 18.04 P4-DPDK networking container: `ipdk install ubuntu1804`
* Ubuntu 20.04 P4-DPDK networking container: `ipdk install ubuntu2004`
* Ubuntu 20.04 eBPF networking container: `ipdk install ebpf-ubuntu2004`
