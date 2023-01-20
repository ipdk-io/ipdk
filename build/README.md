# IPDK Build Directory

This directory contains all of the individual IPDK recipes. These can all be
built using the `ipdk` CLI found here.

## Install IPDK CLI

To fully use all the features of the IPDK containers and if you want to follow
the examples, then install the IPDK CLI with the following command executed
from the directory this README is found in:

 ```bash
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

## Container Build Instructions

From here on, make sure to follow the instructions below while logged into
the vagrant-container virtual machine.

## Section 1: Bring-up IPDK Container

### Pre-requisites to run IPDK container

* Docker is installed and running with correct (proxy) settings.
* Note: Since all dependent packages are installed in docker container, these
  specific settings should be defined on the host machine/server. Eg:
  * A nameserver in `resolv.conf`
  * proxies in `~/.docker/config.json`(<https://docs.docker.com/network/proxy/>)
  * `http-proxy.conf` under docker service.
  * Then restart docker service.
* If you want to push the container to Docker Hub then login to docker using
  `docker login`
* Start docker service using following commands:

  ```command
  systemctl daemon-reload
  systemctl restart docker
  ```

Install the IPDK CLI and set your specific IPDK CLI configuration settings! See
[here](#CLI-configuration-settings) for more information about IPDK CLI
configuration file settings and inner workings!

* If you are behind a proxy, add the `PROXY=<your proxy address>` option to
  add your proxy to your user CLI configuration file.
* By default source code will not be retained in the IPDK container when built.
  If user wants to retain source code, set the (`KEEP_SOURCE_CODE=true`)
  option in the CLI configuration file.
* By default, image will contain all the modules including its dependencies.
  To minimize the image size suitable for K8S or any cloud deployments, set the
  (`DEPLOYMENT_IMAGE=true`) option in the CLI configuration file to keep only
  modules and libraries required for bringing up the stack.

* Set the location of the working directory for the logs, interfaces and
  example VM images by setting the `VOLUME=` option in your user CLI
  configuration file. Default location is `~/.ipdk/volume`

### Commands to bring-up IPDK container

* The following commands can be used to build a IPDK container:

  * Run `ipdk build --no-cache` - To build a IPDK docker image.
  * Run `ipdk build --no-cache --use-proxy` - To build a docker image while
    running behind a proxy (set the `PROXY` option, see above!!!).
  * Run `ipdk build` - To build a IPDK docker image with using
    previously cached build data.
  * Run `ipdk build --use-proxy` - To build a docker image while running
    behind a proxy, with using previous cached build's data. (set the
    `PROXY` option, see above!!!)

* In normal environments use `ipdk build --no-cache` Now the container image is
  built, this can take more then 60 minutes depending on the hardware/VM
  configuration.
* When the build is ready, the P4OVS switch can be started as docker
  container daemon with `ipdk start -d`. A `volume` directory will be created
  (depending on option settings at `~/.ipdk/volume`). This directory will be used
  for creating the vhost socket interfaces in `volume/intf`, all the log files in
  `volume/logs` and can be used to share files with the IPDK daemon container
  where the `VOLUME` directory is available as '/tmp'.
* Run 'ipdk connect' - To connect to your IPDK container daemon and to use
  it from a command line.

If above commands are successful, at this point you should have your IPDK
container up and running, and should see the container prompt like below:

```text
    root@c5efb1a949ad ~]#
```

`c5efb1a949ad` is your container id as displayed in command `docker ps -a`

## Platform Specific Docker Instructions

Now that the container is running, please continue with platform specific
container instructions in either the [P4 OVS](networking/README_DOCKER.md)
or [P4 eBPF](networking_ebpf/README_DOCKER.md) files.

## Recipe Specific Build Instructions

Please see the specific IPDK recipe for build instructions:

* [P4 Networking Recipe](networking/README.md)
* [eBPF Networking Recipe](networking_ebpf/README.md)
