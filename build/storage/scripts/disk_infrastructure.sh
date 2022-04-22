#!/usr/bin/env bash

function get_number_of_virtio_blk() {
	cmd="lsblk --output \"NAME,VENDOR,SUBSYSTEMS\""
	out=$( send_command_over_unix_socket "${1}" "${cmd}" 1 )
	number_of_virio_blk_devices=$(echo "${out}" | grep -c "block:virtio:pci")
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

function attach_virtio_blk() {
	proxy_ip="${1}"
	hot_plug_service_port="${2}"
	vm_monitor="${3}"
	virtio_blk_socket="${4}"
	no_grpc_proxy="" grpc_cli call "${proxy_ip}":"${hot_plug_service_port}" HotPlugVirtioBlk \
		"vmId: '${vm_monitor}' vhostVirtioBlkId: '${virtio_blk_socket}'"
	return "$?"
}

function dettach_virtio_blk() {
	proxy_ip="${1}"
	hot_plug_service_port="${2}"
	vm_monitor="${3}"
	virtio_blk_socket="${4}"
	no_grpc_proxy="" grpc_cli call "${proxy_ip}":"${hot_plug_service_port}" HotUnplugVirtioBlk \
		"vmId: '${vm_monitor}' vhostVirtioBlkId: '${virtio_blk_socket}'"
	return $?
}

function create_and_expose_sybsystem_over_tcp() {
	ip_addr="${1}"
	nqn="${2}"

	rpc.py -s "${ip_addr}" nvmf_create_subsystem "${nqn}" \
		-s SPDK00000000000001 -a
	rpc.py -s "${ip_addr}" nvmf_create_transport -t TCP -u 8192
	rpc.py -s "${ip_addr}" nvmf_subsystem_add_listener "${nqn}" -t TCP \
		-f IPv4 -a "${ip_addr}" -s 4420
}

function create_ramdrive_and_attach_as_ns_to_subsystem() {
	ip_addr="${1}"
	ramdrive_name="${2}"
	number_of_512b_blocks="${3}"
	nqn="${4}"

	rpc.py -s "${ip_addr}" bdev_malloc_create -b "${ramdrive_name}" \
		"${number_of_512b_blocks}" 512
	rpc.py -s "${ip_addr}" nvmf_subsystem_add_ns "${nqn}" "${ramdrive_name}"
}

function attach_controller() {
	ip_addr="${1}"
	storage_target_ip_addr="${2}"
	nqn="${3}"
	controller_name="${4}"

	rpc.py -s "${ip_addr}" bdev_nvme_attach_controller -b "${controller_name}" -t TCP \
		-f ipv4 -a "${storage_target_ip_addr}" -s 4420 -n "${nqn}"
}

function create_disk() {
	ip_addr="${1}"
	vhost_path="${2}"
	ns="${3}"
	rpc.py -s "${ip_addr}" vhost_create_blk_controller \
		"${vhost_path}" "${ns}"
}

function attach_ns_as_virtio_blk() {
	proxy_ip="${1}"
	vhost_name="${2}"
	exposed_controller_ns="${3}"
	hot_plug_service_port="${4}"
	vm_monitor="${5}"

	create_disk "${proxy_ip}" \
		"/ipdk-shared/${vhost_name}" "${exposed_controller_ns}"

	attach_virtio_blk "${proxy_ip}" "${hot_plug_service_port}" \
		"${vm_monitor}" "${vhost_name}"
}

function create_subsystem_and_expose_to_another_machine() {
	storage_target_ip="${1}"
	nqn="${2}"
	proxy_ip="${3}"
	controller_name="${4}"
	create_and_expose_sybsystem_over_tcp "${storage_target_ip}" "${nqn}"
	attach_controller "${proxy_ip}" "${storage_target_ip}" "${nqn}" "${controller_name}"
}
