#!/bin/bash
#Copyright (C) 2021-2022 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

stty -echoctl # hide ctrl-c

usage() {
    echo ""
    echo "Usage:"
    echo "rundemo_TAP_IO.sh: -s|--scripts-dir --deps-install-dir --nr-install-dir --sde-install-dir -w|--workdir -h|--help"
    echo ""
    echo "  --deps-install-dir: Networking-recipe dependencies install path. [Default: ${workdir}/networking-recipe/deps_install"
    echo "  -h|--help: Displays help"
    echo "  --nr-install-dir: Networking-recipe install path. [Default: ${workdir}/networking-recipe/install"
    echo "  --p4c-install-dir: P4C install path. [Default: ${workdir}/p4c/install"
    echo "  -s|--scripts-dir: Directory path where all utility scripts copied.  [Default: ${workdir}/scripts]"
    echo "  --sde-install-dir: P4 SDE install path. [Default: ${workdir}/p4-sde/install"
    echo "  -w|--workdir: Working directory"
    echo ""
}

# Parse command-line options.
SHORTOPTS=:h,s:,w:
LONGOPTS=help,deps-install-dir:,nr-install-dir:,p4c-install-dir:,sde-install-dir:,scripts-dir:,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=/root
SCRIPTS_DIR="${WORKING_DIR}"/scripts
DEPS_INSTALL_DIR="${WORKING_DIR}"/networking-recipe/deps_install
P4C_INSTALL_DIR="${WORKING_DIR}"/p4c/install
SDE_INSTALL_DIR="${WORKING_DIR}"/p4-sde/install
NR_INSTALL_DIR="${WORKING_DIR}"/networking-recipe/install

# Process command-line options.
while true ; do
    case "${1}" in
    --deps-install-dir)
        DEPS_INSTALL_DIR="${2}"
        shift 2 ;;
    -h|--help)
        usage
        exit 1 ;;
    --nr-install-dir)
        NR_INSTALL_DIR="${2}"
        shift 2 ;;
    --p4c-install-dir)
        P4C_INSTALL_DIR="${2}"
        shift 2 ;;
    --sde-install-dir)
        SDE_INSTALL_DIR="${2}"
        shift 2 ;;
    -s|--scripts-dir)
        SCRIPTS_DIR="${2}"
        shift 2 ;;
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

ip netns del VM0
ip netns del VM1

killall infrap4d


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

. "${SCRIPTS_DIR}"/set_hugepages.sh

. "${SCRIPTS_DIR}"/setup_nr_cfg_files.sh --nr-install-dir="${NR_INSTALL_DIR}" \
      --sde-install-dir="${SDE_INSTALL_DIR}"

. "${SCRIPTS_DIR}"/run_infrap4d.sh --nr-install-dir="${NR_INSTALL_DIR}"
popd || exit

echo ""
echo "Creating TAP ports"
echo ""

pushd "${WORKING_DIR}" || exit
# Wait for networking-recipe processes to start gRPC server and open ports for clients to connect.
sleep 1

gnmi-ctl set "device:virtual-device,name:TAP0,pipeline-name:pipe,\
    mempool-name:MEMPOOL0,mtu:1500,port-type:TAP"
gnmi-ctl set "device:virtual-device,name:TAP1,pipeline-name:pipe,\
    mempool-name:MEMPOOL0,mtu:1500,port-type:TAP"
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
echo "Create two Namespaces"
echo ""

ip netns add VM0
ip netns add VM1

echo ""
echo "Move TAP ports to respective namespaces and bringup the ports"
echo ""

ip link set TAP0 netns VM0
ip netns exec VM0 ip link set dev TAP0 up
ip link set TAP1 netns VM1
ip netns exec VM1 ip link set dev TAP1 up

echo ""
echo "Assign IP addresses to the TAP ports"
echo ""

ip netns exec VM0 ip addr add 1.1.1.1/24 dev TAP0
ip netns exec VM1 ip addr add 2.2.2.2/24 dev TAP1

echo ""
echo "Add ARP table for neighbor TAP port"
echo ""

ip netns exec VM0 ip neigh add 2.2.2.2 dev TAP0 lladdr $(ip netns exec VM1 ip -o link show TAP1 | awk -F" " '{print $17}')
ip netns exec VM1 ip neigh add 1.1.1.1 dev TAP1 lladdr $(ip netns exec VM0 ip -o link show TAP0 | awk -F" " '{print $17}')

echo ""
echo "Add Route to reach neighbor TAP port"
echo ""

ip netns exec VM0 ip route add 2.2.2.0/24 via 1.1.1.1 dev TAP0
ip netns exec VM1 ip route add 1.1.1.0/24 via 2.2.2.2 dev TAP1

echo ""
echo "Programming P4 pipeline"
echo ""

p4rt-ctl set-pipe br0 "${WORKING_DIR}"/examples/simple_l3/simple_l3.pb.bin \
    "${WORKING_DIR}"/examples/simple_l3/p4Info.txt
p4rt-ctl add-entry br0 ingress.ipv4_host \
    "hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"
p4rt-ctl add-entry br0 ingress.ipv4_host \
    "hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"

echo ""
echo "Ping from TAP0 port to TAP1 port"
echo ""
ip netns exec VM0 ping 2.2.2.2 -c 5
ip netns exec VM1 ping 1.1.1.1 -c 5
