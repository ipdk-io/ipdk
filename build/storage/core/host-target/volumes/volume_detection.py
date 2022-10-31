# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import logging
import os
import glob

from volumes import VolumeError, VolumeId, Volume
from pci import PciAddress


def get_directories(path: str) -> list[str]:
    unused0, dirs, unused1 = next(os.walk(path))
    return dirs


def get_all_files_by_pattern(pattern: str) -> list[str]:
    return glob.glob(pattern)


class InvalidPciAddress(ValueError):
    pass


class FailedVolumeDetection(RuntimeError):
    pass


def get_virtio_blk_volume(
    addr: PciAddress, volume_ids: set[VolumeId] = set()
) -> set[Volume]:
    if volume_ids:
        raise FailedVolumeDetection(
            f"Volume id '{volume_ids}' cannot be specified for virtio-blk devices,"
            + "since virtio-blk always associated with one volume"
        )
    block_directory_pattern = os.path.join(
        os.path.join("/sys/bus/pci/devices", str(addr).lower()), "virtio*/block"
    )
    block_device_matches = get_all_files_by_pattern(block_directory_pattern)
    if len(block_device_matches) == 0:
        raise FailedVolumeDetection(
            "No devices found for pattern " + block_directory_pattern
        )
    elif len(block_device_matches) > 1:
        raise FailedVolumeDetection(
            "Found more than one device for pattern"
            + block_directory_pattern
            + " : "
            + str(block_device_matches)
        )
    devices = get_directories(block_device_matches[0])
    if not devices or len(devices) == 0:
        raise FailedVolumeDetection(
            "No device exist under "
            + block_directory_pattern
            + " for pci device '"
            + str(addr)
            + "'"
        )
    elif len(devices) > 1:
        raise FailedVolumeDetection(
            "Multiple devices are detected "
            + str(devices)
            + " for pci address '"
            + str(addr)
            + "'"
        )
    device_path = os.path.join("/dev", devices[0])
    return {Volume(device_path)}


def get_nvme_volumes(
    addr: PciAddress, volume_ids: set[VolumeId] = set()
) -> set[Volume]:
    namespace_directories_pattern = os.path.join(
        os.path.join("/sys/bus/pci/devices", str(addr).lower()), "nvme/nvme*/nvme*n*"
    )

    namespaces_in_sysfs = get_all_files_by_pattern(namespace_directories_pattern)
    if volume_ids:
        namespaces_in_sysfs = _match_namespaces_to_volumes(
            namespaces_in_sysfs, volume_ids
        )
    if not namespaces_in_sysfs:
        logging.warning(f"Cannot find device for '{str(addr)}' '{str(volume_ids)}'")

    return _find_namespaces_in_dev(namespaces_in_sysfs)


def _match_namespaces_to_volumes(
    namespaces_in_sysfs: list[str], volume_ids: set[VolumeId]
) -> list[str]:
    filtered_namespaces_in_sysfs = []
    for namespace in namespaces_in_sysfs:
        namespace_uuid_file = os.path.join(namespace, "uuid")
        namespace_uuid = ""
        with open(namespace_uuid_file) as f:
            namespace_uuid = f.read()

        if VolumeId(namespace_uuid) in volume_ids:
            filtered_namespaces_in_sysfs.append(namespace)
    return filtered_namespaces_in_sysfs


def _find_namespaces_in_dev(namespaces_in_sysfs: list[str]) -> set[Volume]:
    from string import digits

    namespace_dev_paths = set()
    for namespace_in_sysfs in namespaces_in_sysfs:
        dev = os.path.basename(namespace_in_sysfs)
        namespace_dev_path = os.path.join("/dev", dev)
        if not os.path.exists(namespace_dev_path) and "c" in namespace_dev_path:
            # TODO Find a way to find namespaces without such low-level modifications
            c_position = dev.find("c")
            if c_position != -1:
                namespace = dev[:c_position] + dev[c_position + 1 :].lstrip(digits)
                namespace_dev_path = os.path.join("/dev", namespace)

        if not os.path.exists(namespace_dev_path):
            raise VolumeError(
                f"Couldn't find device to exercise for: {namespace_dev_path}"
            )

        namespace_dev_paths.add(Volume(namespace_dev_path))
    return namespace_dev_paths
