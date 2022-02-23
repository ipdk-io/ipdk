# IPDK Container (Version 0.1.0)

## What is IPDK container?
The IPDK Container is a Virtual Networking Infrastructure Container and is
built with the following components:

1. [OvS with P4 Support](https://github.com/ipdk-io/ovs/tree/ovs-with-p4)
2. [P4_DPDK_target library](https://github.com/p4lang/p4-dpdk-target)
3. [P4-DPDK](https://github.com/DPDK/dpdk)
4. [P4C P4 reference compiler with DPDK, eBPF target support](https://github.com/p4lang/p4c)
5. OVS pipeline builder program
6. P4 Pipeline program examples

The IPDK container dockerfile builds all the five components and their dependencies
and integrates them providing a P4 based virtual networking switch, P4
compiler + builder and example p4 pipeline code within the container. Following
sections decribe the steps on how to bring up and run this container and use
the example P4 pipeline programs.

## Optional Vagrant Setup

To ease usage of the IPDK P4OVS container, a Vagrant environment is provided
which will spinup an Ubuntu VM with Docker already installed, allowing for a
quick way to play with the containerized version of P4OVS.

### Supported Vagrant + Virtualbox Setups

The Vagrant setup is currently only tested with Virtualbox running on MacOS. As
more uses test and report things working, this will be updated.

It's also not advised to run multiple hypervisors at the same time, as this can lead
to trouble with sharing the CPU's virtualization extensions.

### Bringup the Vagrant VM:
```
$ cd vagrant-container
$ vagrant up
```

### Login to the VM
```
$ vagrant ssh
Welcome to Ubuntu 20.04 LTS (GNU/Linux 5.4.0-31-generic x86_64)

                  ubuntu-20.04-amd64-docker (virtualbox)
                 _____ _____ _____ _____ _____ _____ _____
                |  |  |  _  |   __| __  |  _  |   | |_   _|
                |  |  |     |  |  |    -|     | | | | | |
                 \___/|__|__|_____|__|__|__|__|_|___| |_|
                       Sat May 23 14:38:33 UTC 2020
                            Box version: 0.1.1

  System information as of Wed 22 Dec 2021 05:47:40 PM UTC

  System load:  1.08               Processes:                141
  Usage of /:   12.1% of 38.65GB   Users logged in:          0
  Memory usage: 3%                 IPv4 address for docker0: 172.17.0.1
  Swap usage:   0%                 IPv4 address for eth0:    10.0.2.15

vagrant@ubuntu2004:~$
```

From here on, make sure to follow the instructions below while logged into
the vagrant-container virtual machine.

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

## Section 1: Bring-up IPDK Container

### Pre-requisites to run IPDK container
- Docker is installed and running with correct (proxy) settings.
- Note: Since all dependent packages are installed in docker container, these
  specific settings should be defined on the host machine/server.
  Eg:
    * A nameserver in `resolv.conf`
    * proxies in `~/.docker/config.json` (https://docs.docker.com/network/proxy/)
    * `http-proxy.conf` under docker service.
    *  Then restart docker service.
- if you want to push the container to Docker Hub then login to docker using
  `docker login`
- Start docker service using following commands:

``` 
$ systemctl daemon-reload
$ systemctl restart docker
```

Install the IPDK CLI and set your specific IPDK CLI configuration settings! See
[here](#CLI-configuration-settings) for more information about IPDK CLI
configuration file settings and inner workings!

- If you are behind a proxy, add the `PROXY=<your proxy address>` option to
  add your proxy to your user CLI configuration file.
- By default source code for P4-OVS, p4-driver and P4C will not be retained in
  the IPDK container when build. If user wants to retain source code, set the
  (`KEEP_SOURCE_CODE=true`) option in the CLI configuration file.
- Set the location of the working directory for the logs, interfaces and
  example VM images by setting the `VOLUME=` option in your user CLI
  configuration file. Default location is `~/.ipdk/volume`

### Commands to bring-up IPDK container and run OvS with P4
   
* The following commands can be used to build a IPDK container:
    1. Run `ipdk build --no-cache` - To build a IPDK docker image.
    2. Run `ipdk build --no-cache --use-proxy ` - To build a docker image while
       running behind a proxy (set the `PROXY` option, see above!!!).
    3. Run `ipdk build` - To build a IPDK docker image with using
       previously cached build data.
    4. Run `ipdk build --use-proxy` - To build a docker image while running
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

* Run - `ipdk connect` - To connect to your IPDK container daemon and to use
it from a command line.

If above commands are successful, at this point you should have your IPDK
container up and running, and should see the container prompt like below:

```
    root@c5efb1a949ad ~]#
```

`c5efb1a949ad` is your container id as displayed in command `docker ps -a`

As your P4-OvS should be up and running, you could see the ovsdb-server
and ovs-vswitchd process with the `ps -ef | grep ovs` command.

## Section 2: Running example setup ( VM1 <-> IPDK Container <-> VM2 )
Below commands will help you setup traffic between 2 VMs on your host with the
IPDK container as a P4 program enabled vswitch switching traffic between them.

Pre-requisite:
- Container in Section 1 should be up and with OvS running
- If you are running in a VM then make sure you have nested virtualization
  enabled on your guest VM
- QEMU and KVM should be installed and running

### Example description

The demo environment is easily setup. The command below will set the environment up and allow for simple testing using the P4OVS container:

```
ipdk demo
```

When executed go to the 'Connect to the test VMs serial consoles' paragraph
below.

### Step-by-step commands to setup the example scenario

If you want to execute each command yourself instead of using the pre-written
demo script, do the following steps:

1) Create 2 vhost ports using GNMI CLI commands through the `ipdk execute` CLI:

```
ipdk execute --- gnmi-cli set "device:virtual-device,name:net_vhost0,host:host1,device-type:VIRTIO_NET,queues:1,socket-path:/tmp/intf/vhost-user-0,port-type:LINK"

ipdk execute --- gnmi-cli set "device:virtual-device,name:net_vhost1,host:host1,device-type:VIRTIO_NET,queues:1,socket-path:/tmp/intf/vhost-user-1,port-type:LINK"
```

2) On your host, create two Ubuntu demo VM images with accompanying cloud-init images:

```
ipdk createvms
```

3) Those two created VM images can at any moment be started with:

```
ipdk startvms
```

4) Create a forwarding pipeline program by compiling and package the vSwitch consumable
pipeline binary package by using the pipeline builder:

```
export OUTPUT_DIR=/root/examples/simple_l3
ipdk execute --- p4c --arch psa --target dpdk --output $OUTPUT_DIR/pipe --p4runtime-files $OUTPUT_DIR/p4Info.txt --bf-rt-schema $OUTPUT_DIR/bf-rt.json --context $OUTPUT_DIR/pipe/context.json $OUTPUT_DIR/simple_l3.p4

ipdk execute /root/examples/simple_l3 --- ovs_pipeline_builder --p4c_conf_file=simple_l3.conf --bf_pipeline_config_binary_file=simple_l3.pb.bin
```

5) Add the created pipeline binary package to the running IPDK container P4-OVS switch:

```
ipdk execute --- ovs-p4ctl set-pipe br0 /root/examples/simple_l3/simple_l3.pb.bin /root/examples/simple_l3/p4Info.txt
```

6) Add pipeline table rules:

```
ipdk execute --- ovs-p4ctl add-entry br0 ingress.ipv4_host "hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"

ipdk execute --- ovs-p4ctl add-entry br0 ingress.ipv4_host "hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"
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
defined password `IPDK`. Then you can ping from vm1 to vm2, and P4-OVS will
be used for networking traffic:

```
vagrant@ubuntu2004:~$ telnet localhost 6551
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

# Section 3: Generating dependent files from P4C and OVS pipeline builder:

TODO: change this whole section to ipdk script + explaining in more depth then demo text above

An open-sourced p4lang P4 compiler is integrated as part of the IPDK container.
1) the p4c executable is used to generate dependent files.
   You can execute all these commands on container.
    a. export OUTPUT_DIR=/root/examples/simple_l3/
    b. p4c --arch psa --target dpdk --output $OUTPUT_DIR/pipe --p4runtime-files \
    $OUTPUT_DIR/p4Info.txt --bf-rt-schema $OUTPUT_DIR/bf-rt.json --context \
    $OUTPUT_DIR/pipe/context.json $OUTPUT_DIR/simple_l3.p4

2) Steps to generate pipeline binary file:
Use ovs_pipeline_builder utility to generate pipeline binary file.
    a. cd /root/examples/simple_l3/
    b. ovs_pipeline_builder --p4c_conf_file=simple_l3.conf \
    --bf_pipeline_config_binary_file=simple_l3.pb.bin

Note: As of today <program>.conf is not generated by compiler, in that case
need to manually update this conf file.

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

# Section 4: IPDK CLI inner workings

TODO: Add all specific things about how the IPDK container and cli works.

## [IPDK CLI Configuration settings](#CLI-configuration-settings)

### Configuration files

TODO: Explain how configuration files work (default settings, user settings, execution settings)

### Available settings

TODO: add all configuration options and their working!

KEEP_SOURCE_CODE:

1) If `KEEP_SOURCE_CODE=false` which is a default value then, complete source
code for P4-OVS, p4-driver and P4C will be removed.

2) `KEEP_SOURCE_CODE=true` then, source code for P4-OVS, p4-driver and P4C will
be retained but temporary files generated after building these repositories
will be removed.

# Section 4: Helpful references:

1. /root/OVS-WITH-P4/Documentation/howto/ovs-with-p4-executables.rst
2. /root/OVS-WITH-P4/OVS-WITH-P4-BUILD-README
3. ipdk/build/IPDK_Container/README
4. ipdk/build/IPDK_Container/examples/vhost-vhost/README
5. ipdk/build/IPDK_Container/examples/simple_l3

# Section 6: Copyright

Copyright (C) 2021 Intel Corporation

SPDX-License-Identifier: Apache-2.0
