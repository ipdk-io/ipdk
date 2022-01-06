#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

stty -echoctl # hide ctrl-c

# Exit function
exit_function()
{
    echo "Exiting cleanly"
    pushd /root || exit
    rm -f network-config-v1.yaml meta-data user-data
    rm -rf /tmp/vhost-user-*
    rm -f vm1.qcow2 vm2.qcow2
    popd || exit
}

trap 'exit_function' SIGINT

echo ""
echo "Cleaning from previous run"
echo ""

rm -rf /tmp/vhost-user-*
killall ovsdb-server
killall ovs-vswitchd

#echo ""
#echo "Pulling down cirros image and configuring"
#echo ""
#
#pushd /root || exit
#wget -nc http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img
#cp cirros-0.5.2-x86_64-disk.img vm1.qcow2
#cp cirros-0.5.2-x86_64-disk.img vm2.qcow2
#popd || exit

echo ""
echo "Creating Ubuntu focal image"
echo ""

pushd /root || exit
/git/ipdk/scripts/get-image.sh focal
qemu-img create -f qcow2 -b focal-server-cloudimg-amd64.raw disk.img
rm -f vm1.qcow2 vm2.qcow2
cp disk.img vm1.qcow2
cp disk.img vm2.qcow2
popd || exit


echo ""
echo "Configuring VM networking and creating cloud-init images"
echo ""

cat << EOF >> network-config-v1.yaml
version: 1
config:
  - type: physical
    name: interface0
    mac_address: "52:54:00:34:12:aa"
    subnets:
      - type: static
        address: 1.1.1.1
        netmask: 255.255.255.0
        gateway: 1.1.1.254
  - type: route
    destination: 2.2.2.0/24
    gateway: 1.1.1.1
EOF

cat << EOF >> meta-data
instance-id: 506f2788-9741-4ed8-af53-c6a21383d09a
local-hostname: vm1
EOF

cat << EOF >> user-data
#cloud-config
password: IPDK
chpasswd: { expire: False }
ssh_pwauth: True
runcmd:
  - [ sudo, ip, route, add, "2.2.2.0/24", via, "1.1.1.1", dev, interface0 ]
  - [ sudo, ip, neigh, add, dev, interface0, '2.2.2.2', lladdr, '52:54:00:34:12:bb' ]
EOF

cloud-localds -v --network-config=network-config-v1.yaml \
    seed1.img user-data meta-data

rm -f network-config-v1.yaml meta-data user-data

cat << EOF >> network-config-v1.yaml
version: 1
config:
  - type: physical
    name: interface0
    mac_address: "52:54:00:34:12:bb"
    subnets:
      - type: static
        address: 2.2.2.2
        netmask: 255.255.255.0
        gateway: 2.2.2.254
  - type: route
    destination: 1.1.1.0/24
    gateway: 2.2.2.2
EOF

cat << EOF >> meta-data
instance-id: 606f2788-9741-4ed8-af53-c6a21383d09b
local-hostname: vm2
EOF

cat << EOF >> user-data
#cloud-config
password: IPDK
chpasswd: { expire: False }
ssh_pwauth: True
runcmd:
  - [ sudo, ip, route, add, "1.1.1.0/24", via, "2.2.2.2", dev, interface0 ]
  - [ sudo, ip, neigh, add, dev, interface0, '1.1.1.1', lladdr, '52:54:00:34:12:aa' ]
EOF

cloud-localds -v --network-config=network-config-v1.yaml \
    seed2.img user-data meta-data

rm -f network-config-v1.yaml meta-data user-data

echo ""
echo "Setting hugepages up and starting P4-OVS"
echo ""

pushd /root/P4-OVS || exit
# shellcheck source=/dev/null
source /root/P4-OVS/p4ovs_env_setup.sh /root/p4-sde/install
/root/scripts/set_hugepages.sh
sysctl -w vm.nr_hugepages=8400
/root/scripts/run_ovs.sh
popd || exit

echo ""
echo "Creating ovs-p4 switch"
echo ""

ovs-vsctl add-br ovs-p4

echo ""
echo "Creating vhost-user ports"
echo ""

pushd /root/P4-OVS || exit
# shellcheck source=/dev/null
source /root/P4-OVS/p4ovs_env_setup.sh /root/p4-sde/install
gnmi-cli set "device:virtual-device,name:net_vhost0,host:host1,\
    device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user-0,\
    port-type:LINK"
gnmi-cli set "device:virtual-device,name:net_vhost1,host:host2,\
    device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user-1,\
    port-type:LINK"
popd || exit

echo ""
echo "Generating dependent files from P4C and OVS pipeline builder"
echo ""

export OUTPUT_DIR=/root/examples/simple_l3/
p4c --arch psa --target dpdk --output $OUTPUT_DIR/pipe --p4runtime-files \
    $OUTPUT_DIR/p4Info.txt --bf-rt-schema $OUTPUT_DIR/bf-rt.json \
    --context $OUTPUT_DIR/pipe/context.json $OUTPUT_DIR/simple_l3.p4
pushd /root/examples/simple_l3/ || exit
ovs_pipeline_builder --p4c_conf_file=simple_l3.conf \
    --bf_pipeline_config_binary_file=simple_l3.pb.bin
popd || exit

echo ""
echo "Starting VM1_TAP_DEV"
echo ""

    #-object memory-backend-file,id=mem,size=1024M,mem-path=/hugetlbfs1,share=on \
kvm -smp 1 -m 256M \
    -boot c -cpu host --enable-kvm -nographic \
    -name VM1_TAP_DEV \
    -hda ./vm1.qcow2 \
    -drive file=seed1.img,id=seed,if=none,format=raw,index=1 \
    -device virtio-blk,drive=seed \
    -object memory-backend-file,id=mem,size=256M,mem-path=/mnt/huge,share=on \
    -numa node,memdev=mem \
    -mem-prealloc \
    -chardev socket,id=char1,path=/tmp/vhost-user-0 \
    -netdev type=vhost-user,id=netdev0,chardev=char1,vhostforce \
    -device virtio-net-pci,mac=52:54:00:34:12:aa,netdev=netdev0 \
    -serial telnet::6551,server,nowait &

sleep 5
echo ""
echo "Waiting 10 seconds before starting second VM"
echo ""
for i in {1..10}
do
    sleep 1
    echo -n "."
    if [ "$(( i % 30 ))" == "0" ]
    then
        echo ""
    fi
done
echo ""
echo "Starting VM2_TAP_DEV"
echo ""

kvm -smp 1 -m 256M \
    -boot c -cpu host --enable-kvm -nographic \
    -name VM2_TAP_DEV \
    -hda ./vm2.qcow2 \
    -drive file=seed2.img,id=seed,if=none,format=raw,index=1 \
    -device virtio-blk,drive=seed \
    -object memory-backend-file,id=mem,size=256M,mem-path=/mnt/huge,share=on \
    -numa node,memdev=mem \
    -mem-prealloc \
    -chardev socket,id=char2,path=/tmp/vhost-user-1 \
    -netdev type=vhost-user,id=netdev1,chardev=char2,vhostforce \
    -device virtio-net-pci,mac=52:54:00:34:12:bb,netdev=netdev1 \
    -serial telnet::6552,server,nowait &

echo ""
echo "Programming P4-OVS pipelines"
echo ""

ovs-p4ctl set-pipe br0 /root/examples/simple_l3/simple_l3.pb.bin \
    /root/examples/simple_l3/p4Info.txt
ovs-p4ctl add-entry br0 ingress.ipv4_host \
    "hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"
ovs-p4ctl add-entry br0 ingress.ipv4_host \
    "hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"
