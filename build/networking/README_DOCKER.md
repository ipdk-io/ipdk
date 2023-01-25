# IPDK Container

## What is an IPDK container?

The IPDK Container is a Virtual Networking Infrastructure Container. This is a
development container and proper security measures will need to be implemented
if this is used in production environment. The container is built with the
following components:

1. [IPDK Networking-Recipe with P4 Support](https://github.com/ipdk-io/networking-recipe)
2. [P4_DPDK_target library](https://github.com/p4lang/p4-dpdk-target)
3. [P4-DPDK](https://github.com/DPDK/dpdk)
4. [P4C P4 reference compiler with DPDK, eBPF target support](https://github.com/p4lang/p4c)
5. TDI pipeline builder program
6. P4 Pipeline program examples

The IPDK container Dockerfile builds all the five components and their dependencies
and integrates them providing a P4 based virtual networking switch, P4
compiler + builder and example p4 pipeline code within the container. Following
sections desribe the steps on how to bring up and run this container and use
the example P4 pipeline programs.

## Install IPDK CLI

To fully use all the features of the IPDK containers and if you want to follow
the examples, then install the IPDK CLI with the following command executed
from the directory this README is found in:

 ```bash
 $ git clone https://github.com/ipdk-io/ipdk.git
 $ cd ipdk/build
 $ ./ipdk install
 ```

If your system has not added `~/.local/bin` or `~/bin` to your search PATH then
execute the given `export PATH=<>` command to add the `ipdk` command
to your current environment path each time you open a new terminal to your
system!

*NOTE*: If `$PATH` variable is not updated as mentioned above, use `./ipdk`
everywhere instead of using `ipdk` command directly.

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

## Section 1: Bring-up IPDK Container

### Pre-requisites to run IPDK container

* Docker is installed and running with correct (proxy) settings.
* Note: Since all dependent packages are installed in docker container, these
  specific settings should be defined on the host machine/server. Eg:
  * A nameserver in `resolv.conf`
  * proxies in below files if needed:
    - `~/.docker/config.json`(<https://docs.docker.com/network/proxy/>)
    - `http-proxy.conf` under docker service.
    - /etc/default/docker
  * Then restart docker service.
* If you want to push the container to Docker Hub then login to docker using
  `docker login`
* Start docker service using following commands:

  ```command
  systemctl daemon-reload
  systemctl restart docker
  ```

* If you are behind a proxy update `PROXY` parameter in `scripts/ipdk_default.env` file.
  Example: `PROXY=http://iam.behind.proxy:1234`

Install the IPDK CLI and set your specific IPDK CLI configuration settings! See
[here](#CLI-configuration-settings) for more information about IPDK CLI
configuration file settings and inner workings!

* If you are behind a proxy, add the `PROXY=<your proxy address>` option to
  add your proxy to your user CLI configuration file.
* By default source code will not be retained in the IPDK container when built.
  If the user wants to retain source code, set the (`KEEP_SOURCE_CODE=true`)
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

  * Run `ipdk build --no-cache` - To build an IPDK docker image.
  * Run `ipdk build --no-cache --use-proxy` - To build a docker image while
    running behind a proxy (set the `PROXY` option, see above!!!).
  * Run `ipdk build` - To build an IPDK docker image using
    previously cached build data.
  * Run `ipdk build --use-proxy` - To build a docker image while running
    behind a proxy, using previous cached build's data. (set the
    `PROXY` option, see above!!!)

* In normal environments use `ipdk build --no-cache` Now the container image is
  built, this can take more then 60 minutes depending on the hardware/VM
  configuration.
* When the build is ready, the infrap4d switch can be started as a docker
  container daemon with `ipdk start -d`. A `volume` directory will be created
  (depending on option settings at `~/.ipdk/volume`). This directory will be used
  for creating the vhost socket interfaces in `volume/intf`, all the log files in
  `volume/logs` and can be used to share files with the IPDK daemon container
  where the `VOLUME` directory is available as '/tmp'.

* User can also start IPDK container via docker command.
  * Update `VOLUME` and `CONTAINER_NAME` environment variables, these are defined in `scripts/ipdk_default.env`
  * rm -rf "${VOLUME}"/logs
    rm -rf "${VOLUME}"/intf
    mkdir -p "${VOLUME}"/logs
    mkdir -p "${VOLUME}"/intf
  * docker run --name "${CONTAINER_NAME}" --cap-add ALL --privileged \
               -v "${VOLUME}":/tmp -p 9339:9339 -p 9559:9559 \
               -d --entrypoint /root/scripts/start.sh -it <Image ID> rundaemon

* Run `ipdk connect` - To connect to your IPDK container daemon and to use
  it from a command line. Everytime we login to container via `ipdk connect`,
  TLS certificates will be generated and stored in a specific location.

If above commands are successful, at this point you should have your IPDK
container up and running, and should see the container prompt like below:

```text
    root@c5efb1a949ad ~]#
```

`c5efb1a949ad` is your container id as displayed in command `docker ps -a`


As your Infrap4d process should be up and running, you could see the infrap4d
process with the `ps -ef | grep infrap4d` command.

## Section 2: Running example use case

### Section 2.1: Running example setup with TAP ports.
Infrap4d process is already started with `ipdk start -d` or with manual
steps mentioned above.
Start example usecase by connecting to docker and running script `/root/scripts/rundemo_TAP_IO.sh`,
this script will:
  - Creates TAP ports and moves to two different namespaces.
  - Create a forwarding pipeline binary.
  - Load the target with a forwarding pipeline.
  - Configure rules.
  - Test traffic with Ping between TAP ports.


### Section 2.2: Running example setup ( VM1 <-> IPDK Container <-> VM2 )
Below commands will help you setup traffic between 2 VMs on your host with the
IPDK container as a P4 program enabled vswitch switching traffic between them.

Pre-requisite:
- Container in Section 1 should be up and with Infrap4d running
- If you are running in a VM then make sure you have nested virtualization
  enabled on your guest VM
- QEMU, KVM, libvirt and cloud-utils packages should be installed as per your distribution and running.
- `ipdk` commands executed on host machine works only when container is started
  via `ipdk start -d` and `ipdk connect`. These start commands provides ports
  from container to host machine for gRPC communication.

### Example description

The demo environment is easily setup. The command below will set the environment up and allow for simple testing using the networking-recipe container:

```
ipdk demo
```
Note: Run `ipdk demo` command from the host machine.

When executed go to the 'Connect to the test VMs serial consoles' paragraph
below.

### Step-by-step commands to setup the example scenario

If you want to execute each command yourself instead of using the pre-written
demo script, do the following steps on your host/server:

1) Create 2 vhost ports using GNMI CTL commands through the `ipdk execute` CLI:

```
ipdk execute --- gnmi-ctl set "device:virtual-device,name:net_vhost0,host-name:host1,device-type:VIRTIO_NET,queues:1,socket-path:/tmp/intf/vhost-user-0,port-type:LINK"

ipdk execute --- gnmi-ctl set "device:virtual-device,name:net_vhost1,host-name:host1,device-type:VIRTIO_NET,queues:1,socket-path:/tmp/intf/vhost-user-1,port-type:LINK"
```

2) On your host, create two Ubuntu demo VM images with accompanying cloud-init images:

```
ipdk createvms
```

3) Those two created VM images can at any moment be started with:

```
ipdk startvms
```

*NOTE*: If VM's are not up even after waiting for 6-9 minutes, check if
hugepages are mounted to `/mnt/huge`.
  Example: Command to mount huge pages is `mount -t hugetlbfs nodev /mnt/huge`

4) Create a forwarding pipeline program by compiling and package the vSwitch consumable
pipeline binary package by using the pipeline builder:

```
export OUTPUT_DIR=/root/examples/simple_l3
ipdk execute --- p4c --arch psa --target dpdk --output $OUTPUT_DIR/pipe --p4runtime-files $OUTPUT_DIR/p4Info.txt --bf-rt-schema $OUTPUT_DIR/bf-rt.json --context $OUTPUT_DIR/pipe/context.json $OUTPUT_DIR/simple_l3.p4

ipdk execute /root/examples/simple_l3 --- tdi_pipeline_builder --p4c_conf_file=simple_l3.conf --bf_pipeline_config_binary_file=simple_l3.pb.bin
```

5) Add the created pipeline binary package to the running IPDK container infrap4d switch:

```
ipdk execute --- p4rt-ctl set-pipe br0 /root/examples/simple_l3/simple_l3.pb.bin /root/examples/simple_l3/p4Info.txt
```

6) Add pipeline table rules:

```
ipdk execute --- p4rt-ctl add-entry br0 ingress.ipv4_host "hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"

ipdk execute --- p4rt-ctl add-entry br0 ingress.ipv4_host "hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"
```

From this step you can connect to the test VMs and do some ping tests as described below!

### Connect to the test VMs serial consoles

You will need two login windows, one for each VM:

```
telnet localhost 6551
```

And in another window:

```
telnet localhost 6552
```

You can stop the terminal session anytime by sending `CTRL+]` en then typing `quit[ENTER]`

### Verify guest is finished booting

It may take 6-9 minutes for both guest VMs to finish booting. You can
watch each VM boot over the serial console.

```
[  307.519991] cloud-init[1249]: Cloud-init v. 21.4-0ubuntu1~20.04.1 running 'modules:config' at Thu, 06 Jan 2022 15:27:13 +0000. Up 297.85 seconds.
[  OK  ] Finished Apply the settings specified in cloud-config.
         Starting Execute cloud user/final scripts...
ci-info: no authorized SSH keys fingerprints found for user ubuntu.
<14>Jan  6 15:27:31 cloud-init: #############################################################
<14>Jan  6 15:27:31 cloud-init: -----BEGIN SSH HOST KEY FINGERPRINTS-----
<14>Jan  6 15:27:31 cloud-init: 1024 SHA256:XtiIx3+4O9dXfAapcvgVy9bTY0AadTx67JgIirP8fDU root@vm1 (DSA)
<14>Jan  6 15:27:31 cloud-init: 256 SHA256:8KKnft4X6/5ANZjy4c9Pf8nLPghM25r2h7KQCcmMWJQ root@vm1 (ECDSA)
<14>Jan  6 15:27:31 cloud-init: 256 SHA256:BOyEUuM4iXqSIlaoCcp+wOsLB3w+ZBZLPxxNdEY7WkQ root@vm1 (ED25519)
<14>Jan  6 15:27:32 cloud-init: 3072 SHA256:GYvOtfpGNz7ILw0XZPkKOVZZZ/rRmafsDE1vcq5vptA root@vm1 (RSA)
<14>Jan  6 15:27:32 cloud-init: -----END SSH HOST KEY FINGERPRINTS-----
<14>Jan  6 15:27:32 cloud-init: #############################################################
-----BEGIN SSH HOST KEY KEYS-----
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHN14OCnYTeMh09qRzmWhtXsCgMOQu5S4WLksyBkQsNFil50MPdN8EoE0hh4dw70UzctiMXmQW/vStGeeyLv7OA= root@vm1
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtOReNwl7HPAz5EUR/6mRdACoNszPBcSS9tCUeot7CE root@vm1
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4yha3xcGv+ISubnNDJvnunNXR1RgG2wCUzBz8Cry7DABZ3ykBsAl86y7tmbKa8/OcOl/rwMEQw9UzNU4zFxbB+m8V7hyEcIqdIMrkjwWg2rLZP9LIN+ia7xIm0SjRjH7D4TuGdGp31
-----END SSH HOST KEY KEYS-----
[  317.197933] cloud-init[1278]: Cloud-init v. 21.4-0ubuntu1~20.04.1 running 'modules:final' at Thu, 06 Jan 2022 15:27:29 +0000. Up 313.74 seconds.
[  317.254438] cloud-init[1278]: ci-info: no authorized SSH keys fingerprints found for user ubuntu.
[  317.296920] cloud-init[1278]: Cloud-init v. 21.4-0ubuntu1~20.04.1 finished at Thu, 06 Jan 2022 15:27:32 +0000. Datasource DataSourceNoCloud [seed=/dev/vda][dsmode=net].  Up s
[  OK  ] Finished Execute cloud user/final scripts.
[  OK  ] Reached target Cloud-init target.
```

### Ping across VMs

Once you reach the following, you can login as the user `ubuntu` with the
defined password `IPDK`. Then you can ping from vm1 to vm2, and infrap4d will
be used for networking traffic:

```
ubuntu@vm1:~$ ping -c 5 2.2.2.2
PING 2.2.2.2 (2.2.2.2) 56(84) bytes of data.
64 bytes from 2.2.2.2: icmp_seq=1 ttl=64 time=0.317 ms
64 bytes from 2.2.2.2: icmp_seq=2 ttl=64 time=0.309 ms
64 bytes from 2.2.2.2: icmp_seq=3 ttl=64 time=0.779 ms
64 bytes from 2.2.2.2: icmp_seq=4 ttl=64 time=0.317 ms
64 bytes from 2.2.2.2: icmp_seq=5 ttl=64 time=0.310 ms

--- 2.2.2.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4011ms
rtt min/avg/max/mdev = 0.309/0.406/0.779/0.186 ms
ubuntu@vm1:~$
```

*NOTE*: If user wants to cleanup, manually remove the qemu VM spawned on the
machine and delete existing IPDK docker container with command `ipdk rm`

## Section 3: Generating dependent files from P4C and TDI pipeline builder:
An open-sourced p4lang P4 compiler is integrated as part of the IPDK container.
1) The p4c executable is used to generate dependent files.
   You can execute all these commands on the container.
    a. export OUTPUT_DIR=/root/examples/simple_l3/
    b. p4c --arch psa --target dpdk --output $OUTPUT_DIR/pipe --p4runtime-files \
    $OUTPUT_DIR/p4Info.txt --bf-rt-schema $OUTPUT_DIR/bf-rt.json --context \
    $OUTPUT_DIR/pipe/context.json $OUTPUT_DIR/simple_l3.p4

2) Steps to generate pipeline binary file:
Use tdi_pipeline_builder utility to generate pipeline binary file.
    a. cd /root/examples/simple_l3/
    b. tdi_pipeline_builder --p4c_conf_file=simple_l3.conf \
    --bf_pipeline_config_binary_file=simple_l3.pb.bin

Note: As of today <program>.conf is not generated by the compiler, in that case
you need to manually update this conf file.

## Using and compiling included P4 Example pipelines
Example P4 pipeline implementations included on the IPDK container:

```
    /root/examples/simple_l3/simple_l3.conf
    /root/examples/simple_l3/simple_l3.p4
```

They can be compiled, put through the pipeline builder and made available on
the host in `~/.ipdk/examples`, by executing:

```
    ipdk [options] examples
```

## Section 4: IPDK CLI inner workings

TODO: Add all specific things about how the IPDK container and cli works.

## [IPDK CLI Configuration settings](#CLI-configuration-settings)

### Configuration files

TODO: Explain how configuration files work (default settings, user settings, execution settings)

### Available settings

TODO: add all configuration options and their working!

KEEP_SOURCE_CODE:

1) If `KEEP_SOURCE_CODE=false` which is a default value then, complete source
code for networking-recipe, p4-driver and P4C will be removed.

2) `KEEP_SOURCE_CODE=true` then, source code for networking-recipe, p4-driver and P4C will
be retained but temporary files generated after building these repositories
will be removed.

DEPLOYMENT_IMAGE:

1) If `DEPLOYMENT_IMAGE=false` which is a default value then,  all libraries
and binaries of modules networking-recipe, p4-driver and P4C are retained without removing
any files generated by the build process.

2) If `DEPLOYMENT_IMAGE=true` then, all libraries and binaries of modules
networking-recipe and p4-driver required for bringing up the stack are retained.


## Section 5: Copyright

Copyright (C) 2021-2023 Intel Corporation

SPDX-License-Identifier: Apache-2.0
