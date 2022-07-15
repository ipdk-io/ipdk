#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

export DEFAULT_SPDK_PORT=5260
export DEFAULT_SMA_PORT=8080
export DEFAULT_NVME_PORT=4420
export MAX_NUMBER_OF_NAMESPACES_ON_COTROLLER=1024

function get_number_of_virtio_blk() {
	cmd="lsblk --output \"NAME\""
	out=$( send_command_over_unix_socket "${1}" "${cmd}" 1 )
	number_of_virio_blk_devices=$(echo "${out}" | grep -c "vd")
	echo "${number_of_virio_blk_devices}"
}

function is_virtio_blk_attached() {
	number_of_virio_blk_devices=$(get_number_of_virtio_blk "${1}")

	if [[ "${number_of_virio_blk_devices}" == 0 ]]; then
		echo "virtio-blk is not found"
		return 1
	else
		echo "virtio-blk is found"
		return 0
	fi
}

function is_virtio_blk_not_attached() {
	if is_virtio_blk_attached "${1}"; then
		return 1
	fi

	return 0
}

function check_number_of_virtio_blk_devices() {
	vm_serial="${1}"
	expected_number_of_devices="${2}"
	number_of_devices=$(get_number_of_virtio_blk "${vm_serial}")
	if [[ "${number_of_devices}" != "${expected_number_of_devices}" ]]; then
		echo "Required number of devices '${expected_number_of_devices}' does"
		echo "not equal to actual number of devices '${number_of_devices}'"
		return 1
	else
		echo "Number of attached virtio-blk devices is '${number_of_devices}'"
		return 0
	fi
}

function create_and_expose_sybsystem_over_tcp() {
	ip_addr="${1}"
	nqn="${2}"
	port_to_expose="${3:-"$DEFAULT_NVME_PORT"}"
	storage_target_port="${4:-"$DEFAULT_SPDK_PORT"}"

	rpc.py -s "${ip_addr}" -p "$storage_target_port" \
		nvmf_create_subsystem "${nqn}" \
		-s SPDK00000000000001 -a \
		-m "$MAX_NUMBER_OF_NAMESPACES_ON_COTROLLER"
	rpc.py -s "${ip_addr}" -p "$storage_target_port" \
		nvmf_create_transport -t TCP -u 8192
	rpc.py -s "${ip_addr}" -p "$storage_target_port" \
		nvmf_subsystem_add_listener "${nqn}" -t TCP \
		-f IPv4 -a "${ip_addr}" -s "${port_to_expose}"
}

function create_ramdrive_and_attach_as_ns_to_subsystem() {
	ip_addr="${1}"
	ramdrive_name="${2}"
	ramdrive_size_in_mb="${3}"
	nqn="${4}"
	storage_target_port="${5:-"$DEFAULT_SPDK_PORT"}"

	rpc.py -s "${ip_addr}" -p "${storage_target_port}" \
		bdev_malloc_create -b "${ramdrive_name}" \
		"${ramdrive_size_in_mb}" 512 &> /dev/null
	rpc.py -s "${ip_addr}" -p "${storage_target_port}" \
		nvmf_subsystem_add_ns "${nqn}" "${ramdrive_name}"
	device_uuid=$(rpc.py -s "${ip_addr}" bdev_get_bdevs | \
		jq -r ".[] | select(.name==\"${ramdrive_name}\") | .uuid")
	echo "$device_uuid"
}

function uuid2base64() {
	python3 <<- EOF
		import base64, uuid
		print(base64.b64encode(uuid.UUID("$1").bytes).decode())
	EOF
}

function wait_for_virtio_blk_in_os() {
	local virtio_blk_handle="$1"
	local wait_for_virtio_blk_sec="$2"

	echo "$virtio_blk_handle" > /dev/null
	# placeholder function for now
	sleep "$wait_for_virtio_blk_sec"
	return 0
}

function _create_virtio_blk() {
	ipu_storage_container_ip="${1}"
	sma_port="${2}"
	volume_id="${3}"
	physical_id="${4}"
	virtual_id="${5}"
	hostnqn="${6}"
	traddr="${7}"
	trsvcid="${8}"

	sma-client.py --address="$ipu_storage_container_ip" --port="$sma_port" <<- EOF
	{
		"method": "CreateDevice",
		"params": {
			"volume": {
				"volume_id": "$(uuid2base64 "${volume_id}")",
				"nvmf": {
					"hostnqn": "${hostnqn}",
					"discovery": {
						"discovery_endpoints": [
							{
								"trtype": "tcp",
								"traddr": "${traddr}",
								"trsvcid": "${trsvcid}"
							}
						]
					}
				}
			},
			"virtio_blk": {
				"physical_id": ${physical_id},
				"virtual_id": ${virtual_id}
			}
		}
	}
	EOF
}

function create_virtio_blk() {
	local disk_handle=""
	disk_handle=$(create_virtio_blk_without_disk_check "$@")
	local wait_for_virtio_blk_sec=2
	wait_for_virtio_blk_in_os "$disk_handle" "$wait_for_virtio_blk_sec"

	echo "$disk_handle"
}

function create_virtio_blk_without_disk_check() {
	ipu_storage_container_ip="${1}"
	volume_id="${2}"
	physical_id="${3}"
	virtual_id="${4}"
	hostnqn="${5}"
	traddr="${6}"
	trsvcid="${7:-"$DEFAULT_NVME_PORT"}"
	sma_port="${8:-"$DEFAULT_SMA_PORT"}"

	device_handle=$(_create_virtio_blk "$ipu_storage_container_ip" "$sma_port" \
					"$volume_id" "$physical_id" "$virtual_id" "$hostnqn" \
					"$traddr" "$trsvcid" | jq -r '.handle')
	echo "$device_handle"
}

function delete_virtio_blk() {
	ipu_storage_container_ip="${1}"
	device_handle="${2}"
	sma_port="${3:-"$DEFAULT_SMA_PORT"}"

	sma-client.py --address="$ipu_storage_container_ip" --port="$sma_port" <<- EOF
	{
		"method": "DeleteDevice",
		"params": {
			"handle": "${device_handle}"
		}
	}
	EOF
	return $?
}

function is_port_on_ip_addr_open() {
	local ip_addr="$1"
	local port="$2"
	timeout 1 bash -c "cat < /dev/null > /dev/tcp/${ip_addr}/${port}" &> /dev/null
	return $?
}

function wait_until_port_on_ip_addr_open() {
	local ip_addr="$1"
	local port="$2"
	local wait_for_sec="${3:-5}"
	local wait_counter=0

	while [ "${wait_counter}" -le "${wait_for_sec}" ] ; do
		if is_port_on_ip_addr_open "$ip_addr" "$port"; then
			return 0
		fi
		sleep 1
		wait_counter=$(( wait_counter + 1 ))
	done
	return 1
}
