# IPDK Container (Version 0.1.0)

IPDK Container is a Virtual Networking Infrastructure Container. IPDK Container
 is built with the following components:

1. OvS with P4 Support (https://github.com/ipdk-io/ovs/tree/ovs-with-p4) 
2. P4_DPDK_target library (https://github.com/p4lang/p4-dpdk-target)
3. P4-DPDK (https://github.com/DPDK/dpdk)

The container builds all the three components and their dependencies and 
integrates them within OvS providing a P4 based virtual networking switch 
within the container. Following are the steps on how to bring up and run this 
container -

## Section 1:  Bring-up IPDK Container

### Pre-requisites to run IPDK container
- Docker utility is installed and running with correct proxy settings.
- Note: Since all dependent packages are installed in docker container, these
  specific settings should be from host machine/server.
  Eg: Nameserver in resolv.conf
      proxies in ~/.docker/config.json (https://docs.docker.com/network/proxy/)
      http-proxy.conf under docker service. Then restart docker service.
- Login to docker using docker login
- Start docker service using following commands:

``` 
$ systemctl daemon-reload
$ systemctl restart docker
```

Note: Build and run your IPDK Fedora33 container from `build/IPDK_Container`
 directory or Ubuntu20.04 container from `build/IPDK_Container/Ubuntu20.04`
 directory in `https://github.com/ipdk-io/ipdk` repository.

### Source Code availability
By default source code for P4-OVS, p4-driver and P4C will not be retained.
If user wants to retain source code, a variable (KEEP_SOURCE_CODE) in
docker.env file is available. User can modify this variable to get results
as mentioned below.

1) If `KEEP_SOURCE_CODE=NO` which is a default value then, complete source code
   for P4-OVS, p4-driver and P4C will be removed.

2) `KEEP_SOURCE_CODE=YES` then, source code for P4-OVS, p4-driver and P4C will
   be retained but temporary files generated after building these repositories
   will be removed.

### Commands to bring-up container and run OvS with P4
* If user is behind a proxy, edit proxy parameter in `IPDK_Container/docker.env`
   and `IPDK_Container/start_p4ovs.sh` files to add your proxy.
   
* The following commands can be used to build:
    1. Run `make build-nc` - To build a docker image while no proxy.
    2. Run `make build-nc-proxy` - To build a docker image while running behind proxy.
    3. Run - `make build` - To build a docker image while no proxy,
        with cached previous build's data.
    4. Run - `make build-proxy` - To build a docker image while running behind proxy, with cached previous build's data.

* Run - `make volume` - To create a shared volume and configure your IPDK
container to use it. This shares `/tmp` directory in your container with 
Mountpoint directory of the docker shared volume. `docker volume inspect shared`
command shows the Mountpoint directory of the host machine/server.

If above commands are successful, at this point you should have your IPDK 
container up and running. You should see the container prompt like below:

```
    root@c5efb1a949ad ~]# 
```

c5efb1a949ad is your container id as displayed in command `docker ps -a`

* Export the variables:

```
$ cd /root/scripts
$ source p4ovs_env_setup.sh /root/p4-sde/install
```

* Setup hugepages:

```
$ /root/scripts/set_hugepages.sh
```

* Clean old vhost-user ports

```
$ rm -rf /tmp/vhost-user-* (if its a re-run)
```

* Run P4-OvS manually by running:

```
$ /root/scripts/run_ovs.sh
```

At this point your OvS should be up and running and you should see ovsdb-server
and ovs-vswitchd process in `ps -ef | grep ovs` command.

## Section 2: Example scenario setup ( VM1 <-> IPDK Container <-> VM2 )
Below commands will help you setup traffic between 2 VMs on host with 
IPDK container as a vswitch switching traffic between them:

Pre-requisite:

* Pre-built VM qcow2 image.
* Container in Section 1 should be up and with OvS running

### Commands to setup the example scenario
* Cleanup any previously used vhost ports before you re-start OvS:
    1. On container: `rm -rf /tmp/vhost-user-*`
    2. On host: `sudo rm -rf /var/lib/docker/volumes/shared/_data/vhost-user-*` 
       (your mounted directory)

* From within the container create 2 vhost ports using GNMI commands
    1. (If new bash) Run:

```
$ cd /root/scripts/ && source p4ovs_env_setup.sh /root/p4-sde/install
$ alias sudo='sudo PATH="$PATH" HOME="$HOME" LD_LIBRARY_PATH="$LD_LIBRARY_PATH"'
$ sudo gnmi-cli set "device:virtual-device,name:net_vhost0,host:host1,\
       device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user-0,\
       port-type:LINK"
$ sudo gnmi-cli set "device:virtual-device,name:net_vhost1,host:host2,\
       device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user-1,\
       port-type:LINK"
```

* On your host, start your VMs using the following qemu commands or similar. These enable your vhost ports within the VM to communicate with the container.
    * vm1.qcow2 and vm2.qcow2 are the VM images
    * `/var/lib/docker/volumes/shared/_data/` - Shared path with container

#### VM1 boot
```
qemu-kvm -smp 4 -m 1024M \
    -boot c -cpu host -enable-kvm -nographic \
    -L /root/pc-bios -name VM1_TAP_DEV \
    -hda ./vm1.qcow2 \
    -object memory-backend-file,id=mem,size=1024M,mem-path=/dev/hugepages,share=on \
    -mem-prealloc \
    -numa node,memdev=mem \
    -chardev socket,id=char1,path=/var/lib/docker/volumes/shared/_data/vhost-user-0 \
    -netdev type=vhost-user,id=netdev0,chardev=char1,vhostforce \
    -device virtio-net-pci,mac=00:e8:ca:11:aa:01,netdev=netdev0 \
    -serial telnet::6551,server,nowait &
```

#### VM2 boot
```
qemu-kvm -smp 4 -m 1024M \
    -boot c -cpu host -enable-kvm -nographic \
    -L /root/pc-bios -name VM2_TAP_DEV \
    -hda ./vm2.qcow2 \
    -object memory-backend-file,id=mem,size=1024M,mem-path=/dev/hugepages,share=on \
    -mem-prealloc \
    -numa node,memdev=mem \
    -chardev socket,id=char2,path=/var/lib/docker/volumes/shared/_data/vhost-user-1 \
    -netdev type=vhost-user,id=netdev1,chardev=char2,vhostforce \
    -device virtio-net-pci,mac=00:e8:ca:11:bb:01,netdev=netdev1 \
    -serial telnet::6552,server,nowait &
```

* On VMs: Configure IP-Address and static ARP/route for both VMs. 
Following is an example:

#### VM1 networking
One vm1 run:

```
$ ifconfig eth0 1.1.1.1/24 up
$ ip route add 2.2.2.0/24 via 1.1.1.1 dev eth0
$ ip neigh add dev eth0 2.2.2.2 lladdr 00:e8:ca:11:bb:01
```

#### VM2 networking
On vm2 run:

```
$ ifconfig eth0 2.2.2.2/24 up
$ ip route add 1.1.1.0/24 via 2.2.2.2 dev eth0
$ ip neigh add dev eth0 1.1.1.1 lladdr 00:e8:ca:11:aa:01
```

* On your Container: Configure Forwarding pipeline config and config rule.
  * Set pipelines. Refer to section 3 for how to create these input files from P4.

```
$ sudo ovs-p4ctl set-pipe br0 /root/examples/simple_l3/simple_l3.pb.bin /root/examples/simple_l3/p4Info.txt
```

  * Configure rule 1:

```
$ sudo ovs-p4ctl add-entry br0 ingress.ipv4_host \
       "hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"
```
  * Configure rule 2:

```
$ sudo ovs-p4ctl add-entry br0 ingress.ipv4_host \
       "hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"
```

* Ping from VM1 to VM2 and it should be successful, which means the traffic 
is switched by the OVS container rules and forwarded between VMs

## Section 3: Generating dependent files from P4C and OVS pipeline builder:
Open-sourced p4lang P4 compiler is integrated as part of container. 

* p4c executable is used to generate dependent files. 
   You can execute all these commands on container.

```
$ export OUTPUT_DIR=/root/examples/simple_l3/
$ p4c --arch psa --target dpdk --output $OUTPUT_DIR/pipe --p4runtime-files \
    $OUTPUT_DIR/p4Info.txt --bf-rt-schema $OUTPUT_DIR/bf-rt.json --context \
    $OUTPUT_DIR/pipe/context.json $OUTPUT_DIR/simple_l3.p4
```

* Steps to generate pipeline binary file:
Use ovs_pipeline_builder utility to generate pipeline binary file.

```
$ cd /root/examples/simple_l3/
$ ovs_pipeline_builder --p4c_conf_file=simple_l3.conf \
    --bf_pipeline_config_binary_file=simple_l3.pb.bin
```

Note: As of today <program>.conf is not generated by compiler, in that case 
need to manually update this conf file.

Example files on container: /root/examples/simple_l3/simple_l3.conf
  			    /root/examples/simple_l3/simple_l3.p4

## Section 4: Helpful references:
1. /root/OVS-WITH-P4/Documentation/howto/ovs-with-p4-executables.rst
2. /root/OVS-WITH-P4/OVS-WITH-P4-BUILD-README
3. ipdk/build/IPDK_Container/README
4. ipdk/build/IPDK_Container/examples/vhost-vhost/README
5. ipdk/build/IPDK_Container/examples/simple_l3
