#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# This script allows to access vm ports from the host

current_script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

declare net_mask_bits
declare gateway
declare dhcp_range
declare bridge
# shellcheck disable=SC1091
source "${current_script_dir}"/nat_variables.sh

tap_device="${1}"

bridge_does_not_exist() {
	bridge_name="${1}"
    if bridge vlan show | grep "^${bridge_name}" &> /dev/null; then
		return 1
    else
		return 0
    fi
}

if bridge_does_not_exist "${bridge}"; then
    echo "1" | tee /proc/sys/net/ipv4/ip_forward

	ip link add "${bridge}" type bridge
	ip addr add "${gateway}/${net_mask_bits}" dev "${bridge}"
	ip link set "${bridge}" up

	dnsmasq \
	--interface="${bridge}" \
	--dhcp-range="${dhcp_range}" \
	--listen-address="${gateway}" \
	--pid-file="/var/run/qemu-dnsmasq-${bridge}.pid" \
	--dhcp-leasefile="/var/run/qemu-dnsmasq-${bridge}.leases" \
	--strict-order \
	--except-interface=lo \
	--bind-interfaces \
	--dhcp-no-override

fi

if test "${tap_device}" ; then
	ip addr add 0.0.0.0 dev "${tap_device}"
	ip link set "${tap_device}" up
	ip link set "${tap_device}" master "${bridge}"
fi
