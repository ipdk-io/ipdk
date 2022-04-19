# Setup Firewall Inline Acceleration #

In this readme document, we show the step-by-step guide to setup the firewall inline acceleration setup. We would like to emphasis that this is a poof-of-concept (PoC) quality code and not a production ready code.

The recipe has been validated for the below version of the used software.

| Software | Version/SHA |
|----------|-------------|
| P4-OVS | 5beed7618ec926910140b907f8a4a17c67562545 |
| P4C | 45e5d70245ef8ec691d0d758e1c91a087ecdeb45 |
| p4-driver | 327720e8381a555557b258ef8e3c4134e0f270da |
| VM OS | Ubuntu-20.04.3 |
| VPP | 22.06-rc0 |
| DPDK | 21.11 |

## Section 1: installing p4-ovs in Host

1. Clone the ipdk repo.
	```
	cd /root && git clone https://github.com/ipdk-io/ipdk.git
	```

2. Build P4-OVS

	Use install_p4-ovs.sh script to install the P4-OVS, P4-SDE, and P4C in host using [install_p4-ovs.sh](scripts/install_p4-ovs.sh). Lets assume that ```/root/ipdk_build``` is the build directory.

	```
	mkdir ipdk_build
	cd ipdk/build/inline_acceleration/firewall/scripts
	./install_p4-ovs.sh /root/ipdk_build
	```

	The script install_p4-ovs.sh will create /root/scripts directory and copy required scripts from ipdk/build/inline_acceleration/firewall/scripts directory.

	After the successful p4-ovs build, the following directories will be created.

	```
	/root/ipdk_build/P4-OVS # P4-OVS directry
	/root/ipdk_build/P4C # P4C directory
	/root/ipdk_build/p4-sde # P4SDE directory
	```

## Section 2: Run OVS-with-P4

1. Export the environment variables.
	```
	export PATH="/root/scripts/:${PATH}"
	export PATH="/root/ipdk_build/P4-OVS/:${PATH}"
	source /root/ipdk_build/P4-OVS/p4ovs_env_setup.sh /root/ipdk_build/p4-sde/install
	```

2. Setup hugepages using /root/ipdk/build/networking/scripts/set_hugepages.sh

3. Cleanup any previously used vhost ports, already running OvS, and QEMU instances.
	```
	pkill qemu > out 2> /dev/null
	pkill qemu > out 2> /dev/null
	kill -9 `pidof ovsdb-server` 2> /dev/null
	kill -9 `pidof ovs-vswitchd` 2> /dev/null
	rm -rf /tmp/vhost-user*
	```

4. Start OVS-with-P4 by running the following
	```
	chmod +x /root/scripts/run_ovs.sh
	bash /root/scripts/run_ovs.sh > out 1> /dev/null
	```

	At this point P4-OVS should be up and running. The ovsdb-server, ovs-vswitchd processes can be seen running using ```ps -ef | grep ovs``` command.

5. Create 4 vhost ports using GNMI commands
	```
	gnmi-cli set "device:virtual-device,name:net_vhost0,host:host1,\
	device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user0,\
	port-type:LINK"

	gnmi-cli set "device:virtual-device,name:net_vhost1,host:host2,\
	device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user1,\
	port-type:LINK"

	gnmi-cli set "device:virtual-device,name:net_vhost2,host:host3,\
	device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user2,\
	port-type:LINK"

	gnmi-cli set "device:virtual-device,name:net_vhost3,host:host4,\
	device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user3,\
	port-type:LINK"
	```

6. Configure Firewall pipeline config and config rule on host OVS.
	* Set pipe:
	```
	ovs-p4ctl set-pipe br0 /root/ipdk/build/inline_acceleration/firewall/example/firewall.pb.bin /root/ipdk/build/inline_acceleration/firewall/example/p4Info.txt
	```
	(See [Section 4](#section-4-generating-dependent-files-from-p4c-and-ovs-pipeline-builder) for how to create these input files from P4)

	* Configure Default forwarding rule on host:
	```
	ovs-p4ctl add-entry br0 ingress.egress_default "istd.ingress_port=3,action=ingress.carry_port2(2)"
	```

## Section 3: Start VMs (VPP and Pktgen) for Firewall Offload

Below steps will set up firewall offload using 2 Virtual Machines (VMs) on host with P4-OVS as a vswitch switching traffic between them.

Pre-requisite:

- Pre-built 2 VMs.

1st VM having packet generator, DPDK installed (Refer [section 6](#section-6-installing-packetgen-dpdk-in-vm). 2nd VM having VPP (Refer [section 5](#section-5-installing-vpp-in-vm) to install VPP ) and P4-OVS (Refer [section 1](#section-1-installing-p4-ovs-in-host) to install P4-OVS), DPDK installed.

1. On the host, start the VMs (assuming vm1.img and vm2.img are the VM images located in /root/vms directory) using the following qemu commands or similar. The VMs consume the vhost ports created by the P4-OVS to communicate with the P4-OVS.

	VM1:
	```
	qemu-system-x86_64 \
		-enable-kvm -m 8G -smp cores=10, threads=1, sockets=1 -cpu host \
		-numa node,memdev=mem -mem-prealloc \
		-object memory-backend-file, id=mem,size=8G, mem-path=/dev/hugepages,share=on \
		-hda /root/vms/vm1.img \
		-netdev user,id=nttsip,hostfwd=tcp::10023-:22 -device e1000, netdev=nttsip \
		-chardev socket,id=chr0, path=/tmp/vhost-user0 \
		-chardev socket,id=chr1, path=/tmp/vhost-user2 \
		-netdev vhost-user,id=net0, chardev=chr0, queues=1 \
		-netdev vhost-user,id=net1, chardev=chr1, queues=1 \
		-device virtio-net-pci,netdev=net0, mac=00:e8:ca:11:aa:01 \
		-device virtio-net-pci,netdev=net1, mac=00:e8:ca:11:cc:01 \
		-vnc :3 &
	```

	VM2:
	```
	qemu-system-x86_64 \
		-enable-kvm -m 8G -smp cores=10, threads=1, sockets=1 -cpu host \
		-numa node,memdev=mem -mem-prealloc \
		-object memory-backend-file, id=mem,size=8G, mem-path=/dev/hugepages,share=on \
		-hda /root/vms/vm2.img \
		-netdev user,id=nttsip,hostfwd=tcp::10026-:22 -device e1000, netdev=nttsip \
		-chardev socket,id=chr0, path=/tmp/vhost-user1 \
		-chardev socket,id=chr1, path=/tmp/vhost-user3 \
		-netdev vhost-user,id=net0, chardev=chr0, queues=1 \
		-netdev vhost-user,id=net1, chardev=chr1, queues=1 \
		-device virtio-net-pci,netdev=net0, mac=00:e8:ca:11:bb:01 \
		-device virtio-net-pci,netdev=net1, mac=00:e8:ca:11:dd:01 \
		-vnc :2 &
	```

2. login to VMs using ssh:

	VM1:
	```
	ssh -p 10023 root@localhost
	```

	VM2:
	```
	ssh -p 10026 root@localhost
	```

3. Setup hugepages, bind PCI addresses to vfio-pci driver in both VM’s

	```
	echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode
	modprobe vfio-pci
	echo 3000 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
	cd /root && ./dpdk/usertools/dpdk-devbind.py -b vfio-pci 00:04.0 00:05.0
	```

4. copy /root/ipdk/build/inline_acceleration/firewall/example/p4info.txt and /root/ipdk/build/inline_acceleration/firewall/example/vpp_startup.conf to /root directory in VM2. p4Info.txt file is used by the DPDK virtio PMD to know about the tables and keys used in the underlying firewall pipeline in P4-OVS.

Then build the VPP according to [section 5](#section-5-installing-vpp-in-vm).

5. Run VPP in VM2:

	```
	export no_proxy=localhost, <address of host>
	cd vpp
	./build-root/install-vpp-native/vpp/bin/vpp -c /root/vpp_startup.conf
	```

6. For testing without offload

	Run ```rte_flow_wrapper disable``` in VPP shell (VM2)

7. In VM1, create a pktgen config file as below.
	```
	echo "set 0 dport 3000
	set 0 sport 2000
	set 0 count 00
	set 0  dst ip 200.200.200.2
	set 0 src ip 100.100.100.1/24
	set 0 src mac 00:e8:ca:11:aa:01
	set 0 dst mac 00:e8:ca:11:bb:01
	set 1 src ip 100.100.100.4/24
	set 1 src mac 00:e8:ca:11:cc:01
	set 1 dst mac 00:e8:ca:11:dd:01
	set 0 sport 2000
	set 0 dport 3000
	page 0
	start 0" >> /root/pktgen.cfg
	```

8. Run pktgen-dpdk in VM1:

	```
	export no_proxy=localhost, <address of host>
	cd Pktgen-dpdk/
	./Builddir/app/pktgen -l 3-6 -a 00:04.0 -a 00:05.0 -- -T -P -m "5.0,6.1" -f /root/pktgen.cfg
	```

Run the traffic from pktgen in VM1, traffic can be seen coming on port2. For testing traffic with offload stop traffic and re-run vpp application without running the command ```rte_flow_wrapper disable```. Run the traffic from VM1, traffic can be seen coming on port2 with higher rate. After this successful run, the traffic rate should have increased because of rules offloaded on p4-ovs.

The programmed rules can be cleaned by using the /root/ipdk/build/inline_acceleration/firewall/scripts/clean_rules.sh script.

## Section 4: Generating dependent files from P4C and OVS pipeline builder

IPDK repo was already cloned in /root/ipdk/ as part of section 1.1

P4C was built as part of sction 1.2

1. p4c executable is used to generate dependent files. execute all these commands on host.

	```
	export OUTPUT_DIR=/root/ipdk/build/inline_acceleration/firewall/example

	p4c --arch psa --target dpdk --output $OUTPUT_DIR/pipe --p4runtime-files $OUTPUT_DIR/p4Info.txt --bf-rt-schema $OUTPUT_DIR/bf-rt.json --context $OUTPUT_DIR/pipe/context.json $OUTPUT_DIR/firewall.p4
	```

2. Use ovs_pipeline_builder utility to generate pipeline binary file.

	```
	cd /root/ipdk/build/inline_acceleration/firewall/example

	ovs_pipeline_builder --p4c_conf_file=firewall.conf --bf_pipeline_config_binary_file=firewall.pb.bin
	```

Note: As of today, the conf file (i.e. firewall.conf) is not generated by compiler, in that case need to manually update this conf file. Example firewall.conf file is provided in ipdk/build/inline_acceleration/firewall/example folder.

## Section 5: installing VPP in VM

First, copy /root/ipdk/build/inline_acceleration/firewall/example/p4info.txt from host to  VM2 /root/ directory. Then clone the IPDK repo, VPP repo, apply the VPP patch as below.

```
cd /root && git clone https://github.com/ipdk-io/ipdk.git

git clone git@github.com:FDio/vpp.git  #(Present VPP Version used: v22.06-rc0)

cd vpp

cp /root/ipdk/build/inline_acceleration/firewall/patch/0003-net-virtio-added-rte_flow-capability.patch /root/vpp/build/external/patches/dpdk_21.11/

export OVS_SERVER_IP=<host IP address>

sed -i s/10.0.0.1/$OVS_SERVER_IP/g /root/vpp/build/external/patches/dpdk_21.11/0003-net-virtio-added-rte_flow-capability.patch

git apply 0001-Implement-rte_flow-wrapper-call-from-the-ACL-plugin.patch

make install-dep

make build-release
```

Use the /root/ipdk/build/inline_acceleration/firewall/example/vpp_startup.conf file and configure dpdk PCI addresses.

## Section 6: Installing PacketGen-dpdk in VM

Use the [pktgen getting started guide](https://pktgen-dpdk.readthedocs.io/en/latest/getting_started.html) to install pktgen-dpdk.
