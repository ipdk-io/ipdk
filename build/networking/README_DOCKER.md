# IPDK Container (Version 0.1.0)

## What is IPDK container?
The IPDK Container is a Virtual Networking Infrastructure Container and is
built with the following components:

1. [IPDK Networking Recipe](https://github.com/ipdk-io/networking-recipe)
2. [P4-DPDK](https://github.com/DPDK/dpdk)
3. [P4C P4 reference compiler with DPDK, eBPF target support](https://github.com/p4lang/p4c)
4. P4 Pipeline program examples

The IPDK container dockerfile builds all the components and their dependencies
and integrates them providing a P4 based virtual networking switch, P4
compiler + builder and example p4 pipeline code within the container. Following
sections decribe the steps on how to bring up and run this container and use
the example P4 pipeline programs.

## Optional Vagrant Setup

To ease usage of the IPDK Networking Recipe container, a Vagrant environment is provided
which will spinup an Ubuntu VM with Docker already installed, allowing for a
quick way to play with the containerized version of Networking Recipe.

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

## Platform Specific Container Instructions

Run - 'ipdk connect' - To connect to your IPDK container daemon and to use
it from a command line.

If above commands are successful, at this point you should have your IPDK
container up and running, and should see the container prompt like below:

```
    root@c5efb1a949ad ~]#
```

`c5efb1a949ad` is your container id as displayed in command `docker ps -a`

## Run Networking Recipe
Below commands will help you setup the environment for Networking recipe and
start the infrap4d

### Set up the environment required by infrap4d

'''
export IPDK_RECIPE=/root/networking-recipe
export DEPEND_INSTALL=/root/networking-recipe/deps_install
export SDE_INSTALL=/root/p4-sde/install
export LD_LIBRARY_PATH=$IPDK_RECIPE/install/lib/:$IPDK_RECIPE/install/lib64/:$SDE_INSTALL/lib:$SDE_INSTALL/lib64:$DEPEND_INSTALL/lib:$DEPEND_INSTALL/lib64:$SDE_INSTALL/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
'''

### Set hugepages required for DPDK

Run the hugepages script.

'''
sudo ./root/scripts/set_hugepages.sh
'''

### Export all environment variables to sudo user

'''
alias sudo='sudo PATH="$PATH" HOME="$HOME" LD_LIBRARY_PATH="$LD_LIBRARY_PATH" SDE_INSTALL="$SDE_INSTALL"'
'''

### Run the infrap4d daemon

'''
cd $IPDK_RECIPE
sudo ./install/sbin/infrap4d
'''

By default, infrap4d runs in detached mode. If you want to run infrap4d in attached mode, use the --nodetach option.

  - All infrap4d logs are by default logged under /var/log/stratum.
  - All P4SDE logs are logged in p4_driver.log under $IPDK_RECIPE.
  - All OVS logs are logged under /tmp/ovs-vswitchd.log.

As your infrap4d should be up and running, you could see the infrap4d  process with the ps -ef | grep infrap4d command.

### Run a sample program

Make sure that all the environmental variables are set correctly.

#### Create 2 TAP ports

'''
cd $IPDK_RECIPE

sudo ./install/bin/gnmi-ctl set "device:virtual-device,name:TAP0,pipeline-name:pipe,mempool-name:MEMPOOL0,mtu:1500,port-type:TAP"
sudo ./install/bin/gnmi-ctl set "device:virtual-device,name:TAP1,pipeline-name:pipe,mempool-name:MEMPOOL0,mtu:1500,port-type:TAP"
ifconfig TAP0 up
ifconfig TAP1 up
'''

Note: See gnmi-ctl Readme for more information on the gnmi-ctl utility.

### Create P4 artifacts

'''
export OUTPUT_DIR=/root/examples/simple_l3

'''
#### Generate the artifacts using the p4c compiler installed in the previous step

'''
mkdir $OUTPUT_DIR/pipe
cd /root/p4c/install/bin

./p4c-dpdk --arch pna --target dpdk \
    --p4runtime-files $OUTPUT_DIR/p4Info.txt \
    --bf-rt-schema $OUTPUT_DIR/bf-rt.json \
    --context $OUTPUT_DIR/pipe/context.json \
    -o $OUTPUT_DIR/pipe/simple_l3.spec $OUTPUT_DIR/simple_l3.p4
'''

Note: The above commands will generate three files (p4Info.txt, bf-rt.json, and context.json).

  - Modify simple_l3.conf file to provide correct paths for bfrt-config, context, and config.

  - TDI pipeline builder combines the artifacts generated by p4c compiler to generate a single bin file to be pushed from the controller. Generate binary executable using tdi-pipeline builder command below:
'''
cd $IPDK_RECIPE
./install/bin/tdi_pipeline_builder \
           --p4c_conf_file=$OUTPUT_DIR/simple_l3.conf \
           --bf_pipeline_config_binary_file=$OUTPUT_DIR/simple_l3.pb.bin
'''

### Set forwarding pipeline

'''
cd $IPDK_RECIPE
sudo ./install/bin/p4rt-ctl set-pipe br0 $OUTPUT_DIR/simple_l3.pb.bin $OUTPUT_DIR/p4Info.txt
'''
### Configure forwarding rules

'''
sudo  ./install/bin/p4rt-ctl add-entry br0 ingress.ipv4_host "hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"
sudo  ./install/bin/p4rt-ctl add-entry br0 ingress.ipv4_host "hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"
'''

Note: See p4rt-ctl Readme for more information on p4rt-ctl utility.

### Test traffic between TAP0 and TAP1

Send packet from TAP 0 to TAP1 using scapy and listen on TAP1 using tcpdump.

'''
sendp(Ether(dst="00:00:00:00:03:14", src="a6:c0:aa:27:c8:2b")/IP(src="192.168.1.10", dst="2.2.2.2")/UDP()/Raw(load="0"*50), iface='TAP0')
'''

# Copyright

Copyright (C) 2021 Intel Corporation

SPDX-License-Identifier: Apache-2.0
