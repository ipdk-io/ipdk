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
    python3 <<- EOF
from scripts import disk_infrastructure

print(disk_infrastructure.get_number_of_virtio_blk(socket="${1}"))
EOF
}

function is_virtio_blk_attached() {
    return $(python3 <<- EOF
from scripts import disk_infrastructure

print(disk_infrastructure.is_virtio_blk_attached(socket="${1}"))
EOF
)
}

function is_virtio_blk_not_attached() {
    return $(python3 <<- EOF
from scripts import disk_infrastructure

print(disk_infrastructure.is_virtio_blk_not_attached(socket="${1}"))
EOF
)
}

function check_number_of_virtio_blk_devices() {
    return $(python3 <<- EOF
from scripts import disk_infrastructure

print(
    disk_infrastructure.check_number_of_virtio_blk_devices(
        vm_serial="${1}",
	    expected_number_of_devices=int("${2}")
    )
)
EOF
)
}

function create_and_expose_sybsystem_over_tcp() {
    python3 <<- EOF
from scripts import disk_infrastructure

disk_infrastructure.create_and_expose_subsystem_over_tcp(
    ip_addr="${1}",
    nqn="${2}",
    port_to_expose=int("${3:-"$DEFAULT_NVME_PORT"}"),
    storage_target_port=int("${4:-"$DEFAULT_SPDK_PORT"}")
)
EOF
}

function create_ramdrive_and_attach_as_ns_to_subsystem() {
    python3 <<- EOF
from scripts import disk_infrastructure

print(
    disk_infrastructure.create_ramdrive_and_attach_as_ns_to_subsystem(
        ip_addr="${1}",
        ramdrive_name="${2}",
	    number_of_512b_blocks=int("${3}"),
        nqn="${4}",
	    storage_target_port=int("${5:-"$DEFAULT_SPDK_PORT"}")
    )
)
EOF
}

function uuid2base64() {
    python3 <<- EOF
from scripts import disk_infrastructure

print(disk_infrastructure.uuid2base64(device_uuid="$1"))
EOF
}

function wait_for_virtio_blk_in_os() {
    python3 <<- EOF
from scripts import disk_infrastructure

disk_infrastructure.wait_for_virtio_blk_in_os(
    timeout=float("${2}")
)
EOF
}

function create_virtio_blk() {
    python3 <<- EOF
from scripts import disk_infrastructure

print(
    disk_infrastructure.create_virtio_blk(
        ipu_storage_container_ip="${1}",
        volume_id="${2}",
        physical_id="${3}",
        virtual_id="${4}",
        hostnqn="${5}",
        traddr="${6}",
        trsvcid="${7:-"$DEFAULT_NVME_PORT"}",
	    sma_port=int("${8:-"$DEFAULT_SMA_PORT"}")
    )
)       
EOF
}

function create_virtio_blk_without_disk_check() {
    python3 <<- EOF
from scripts import disk_infrastructure

print(
    disk_infrastructure.create_virtio_blk_without_disk_check(
        ipu_storage_container_ip="${1}",
        volume_id="${2}",
        physical_id="${3}",
        virtual_id="${4}",
        hostnqn="${5}",
        traddr="${6}",
        trsvcid="${7:-"$DEFAULT_NVME_PORT"}",
	    sma_port=int("${8:-"$DEFAULT_SMA_PORT"}")
    )
)
EOF
}

function delete_virtio_blk() {
    return $(python3 <<- EOF
from scripts import disk_infrastructure

print(
    disk_infrastructure.delete_virtio_blk(
        ipu_storage_container_ip="${1}",
        device_handle="${2}",
	    sma_port=int("${3:-"$DEFAULT_SMA_PORT"}")
    )
)
EOF
)
}

function wait_until_port_on_ip_addr_open() {
    return $(python3 <<- EOF
from scripts import disk_infrastructure

print(
    disk_infrastructure.is_port_open(
        ip_addr="$1",
	    port=int("$2"),
	    timeout=float("${3:-5}")
    )
)
EOF
)
}
