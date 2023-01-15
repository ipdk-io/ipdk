#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

stty -echoctl # hide ctrl-c

usage() {
    echo ""
    echo "Usage:"
    echo "rundemo.sh: -w|--workdir -h|--help"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  -w|--workdir: Working directory"
    echo ""
}

# Parse command-line options.
SHORTOPTS=:h,w:
LONGOPTS=help,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=/root

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
        usage
        exit 1 ;;
    -w|--workdir)
        WORKING_DIR="${2}"
        shift 2 ;;
    --)
        shift
        break ;;
    *)
        echo "Internal error!"
        exit 1 ;;
    esac
done

SCRIPTS_DIR="${WORKING_DIR}"/scripts
DEPS_INSTALL_DIR="${WORKING_DIR}"/networking-recipe/deps_install
P4C_INSTALL_DIR="${WORKING_DIR}"/p4c/install
SDE_INSTALL_DIR="${WORKING_DIR}"/p4-sde/install
NR_INSTALL_DIR="${WORKING_DIR}"/networking-recipe/install

# Exit function
exit_function()
{
    echo "Exiting cleanly"
    pushd "${WORKING_DIR}" || exit
    rm -f network-config-v1.yaml meta-data user-data
    pkill qemu
    rm -rf /tmp/vhost-user-*
    rm -f "${WORKING_DIR}"/vm1.qcow2 "${WORKING_DIR}"/vm2.qcow2
    rm -rf "${WORKING_DIR}"/seed1.img "${WORKING_DIR}"/seed2.img
    popd || exit
    exit
}

# Display argument data after parsing commandline arguments
echo ""
echo "WORKING_DIR: ${WORKING_DIR}"
echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
echo "DEPS_INSTALL_DIR: ${DEPS_INSTALL_DIR}"
echo "P4C_INSTALL_DIR: ${P4C_INSTALL_DIR}"
echo "SDE_INSTALL_DIR: ${SDE_INSTALL_DIR}"
echo "NR_INSTALL_DIR: ${NR_INSTALL_DIR}"
echo ""

echo ""
echo "Cleaning from previous run"
echo ""

pkill qemu
rm -rf /tmp/vhost-user-*
killall ovsdb-server
killall ovs-vswitchd
killall infrap4d

echo ""
echo "Creating Ubuntu focal image"
echo ""

pushd "${WORKING_DIR}" || exit
"${SCRIPTS_DIR}"/get-image.sh focal
rm -f vm1.qcow2 vm2.qcow2
cp focal-server-cloudimg-amd64.img vm1.qcow2
cp focal-server-cloudimg-amd64.img vm2.qcow2
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
    "${WORKING_DIR}"/seed1.img user-data meta-data

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
    "${WORKING_DIR}"/seed2.img user-data meta-data

rm -f network-config-v1.yaml meta-data user-data


echo ""
echo "Setting hugepages up and starting networking-recipe processes"
echo ""

unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY

pushd "${WORKING_DIR}" || exit
# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/initialize_env.sh --sde-install-dir="${SDE_INSTALL_DIR}" \
      --nr-install-dir="${NR_INSTALL_DIR}" --deps-install-dir="${DEPS_INSTALL_DIR}" \
      --p4c-install-dir="${P4C_INSTALL_DIR}"

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/set_hugepages.sh

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/setup_nr_cfg_files.sh --nr-install-dir="${NR_INSTALL_DIR}" \
      --sde-install-dir="${SDE_INSTALL_DIR}"

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/run_infrap4d.sh --nr-install-dir="${NR_INSTALL_DIR}"
popd || exit

echo ""
echo "Creating TAP ports"
echo ""

pushd "${WORKING_DIR}" || exit
# Wait for networking-recipe processes to start gRPC server and open ports for clients to connect.
sleep 1

gnmi-ctl set "device:virtual-device,name:net_vhost0,host-name:host1,\
    device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user-0,\
    port-type:LINK"
gnmi-ctl set "device:virtual-device,name:net_vhost1,host-name:host2,\
    device-type:VIRTIO_NET,queues:1,socket-path:/tmp/vhost-user-1,\
    port-type:LINK"
popd || exit

echo ""
echo "Generating dependent files from P4C and pipeline builder"
echo ""

export OUTPUT_DIR="${WORKING_DIR}"/examples/simple_l3/
p4c --arch psa --target dpdk --output "${OUTPUT_DIR}"/pipe --p4runtime-files \
    "${OUTPUT_DIR}"/p4Info.txt --bf-rt-schema "${OUTPUT_DIR}"/bf-rt.json \
    --context "${OUTPUT_DIR}"/pipe/context.json "${OUTPUT_DIR}"/simple_l3.p4

pushd "${WORKING_DIR}"/examples/simple_l3 || exit
tdi_pipeline_builder --p4c_conf_file=simple_l3.conf \
    --bf_pipeline_config_binary_file=simple_l3.pb.bin
popd || exit

echo ""
echo "Starting VM1_TAP_DEV"
echo ""

KVM_PATH=/usr/bin/kvm
QEMU_KVM_PATH=/usr/bin/qemu-kvm
QEMU_BIN_PATH=""

if [ -f "${KVM_PATH}" ]; then
    QEMU_BIN_PATH="kvm"
fi

if [ -f "${QEMU_KVM_PATH}" ]; then
    QEMU_BIN_PATH="qemu-kvm"
fi

echo "Using QEMU: ${QEMU_BIN_PATH}"

pushd "${SCRIPTS_DIR}" || exit
    #-object memory-backend-file,id=mem,size=1024M,mem-path=/hugetlbfs1,share=on \
"${QEMU_KVM_PATH}" -smp 1 -m 256M \
    -boot c -cpu host --enable-kvm -nographic \
    -name VM1_TAP_DEV \
    -hda "${WORKING_DIR}"/vm1.qcow2 \
    -drive file="${WORKING_DIR}"/seed1.img,id=seed,if=none,format=raw,index=1 \
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

"${QEMU_KVM_PATH}" -smp 1 -m 256M \
    -boot c -cpu host --enable-kvm -nographic \
    -name VM2_TAP_DEV \
    -hda "${WORKING_DIR}"/vm2.qcow2 \
    -drive file="${WORKING_DIR}"/seed2.img,id=seed,if=none,format=raw,index=1 \
    -device virtio-blk,drive=seed \
    -object memory-backend-file,id=mem,size=256M,mem-path=/mnt/huge,share=on \
    -numa node,memdev=mem \
    -mem-prealloc \
    -chardev socket,id=char2,path=/tmp/vhost-user-1 \
    -netdev type=vhost-user,id=netdev1,chardev=char2,vhostforce \
    -device virtio-net-pci,mac=52:54:00:34:12:bb,netdev=netdev1 \
    -serial telnet::6552,server,nowait &
popd || exit

echo ""
echo "Programming P4-OVS pipelines"
echo ""

p4rt-ctl set-pipe br0 "${WORKING_DIR}"/examples/simple_l3/simple_l3.pb.bin \
    "${WORKING_DIR}"/examples/simple_l3/p4Info.txt
p4rt-ctl add-entry br0 ingress.ipv4_host \
    "hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"
p4rt-ctl add-entry br0 ingress.ipv4_host \
    "hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"
