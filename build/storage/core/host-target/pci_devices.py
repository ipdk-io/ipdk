# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
from lib2to3.pytree import Base
import os
import re
import glob


pci_validator = re.compile(
    r"[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-1]{1}[0-9a-fA-F]{1}\.[0-7]{1}"
)


class PciAddress:
    def validate_pci_address(pci_address):
        return pci_validator.search(pci_address) != None

    def _parse_pci_address(pci_address):
        split_pci_address = pci_address.replace(".", ":").split(":")
        split_pci_address.reverse()
        function = split_pci_address[0].strip()
        device = split_pci_address[1].strip()
        bus = split_pci_address[2].strip()
        domain = split_pci_address[3].strip()
        return (domain, bus, device, function)

    def __init__(self, pci_address) -> None:
        if not PciAddress.validate_pci_address(pci_address):
            raise InvalidPciAddress(pci_address + " is invalid")
        (
            self.domain,
            self.bus,
            self.device,
            self.function,
        ) = PciAddress._parse_pci_address(pci_address)

    def get_domain_bus_prefix(self):
        return self.domain + ":" + self.bus

    def get_bus_device_function_address(self):
        return self.bus + ":" + self.device + "." + self.function

    def get_full_address(self):
        return self.domain + ":" + self.get_bus_device_function_address()


def get_directories(path):
    if os.path.exists(path):
        unused0, dirs, unused1 = next(os.walk(path))
        return dirs
    else:
        return None


def get_all_files_by_pattern(pattern):
    return glob.glob(pattern)


def find_pci_directory_in_sys_fs(pci_address):
    sys_fs_pci = "/sys/devices/pci*/"
    found_elements = get_all_files_by_pattern(
        sys_fs_pci + pci_address.get_full_address()
    )
    found_elements += get_all_files_by_pattern(
        sys_fs_pci + "/*/" + pci_address.get_full_address()
    )
    if not found_elements:
        raise FailedPciDeviceDetection(
            "No pci device with " + pci_address.get_full_address() + " found"
        )
    return found_elements[0]


class InvalidPciAddress(ValueError):
    pass


class FailedPciDeviceDetection(RuntimeError):
    pass


def get_virtio_blk_path_by_pci_address(pci_address):
    addr = PciAddress(pci_address)

    pci_device_dir = find_pci_directory_in_sys_fs(addr)
    block_directory_pattern = os.path.join(pci_device_dir, "virtio*/block")
    block_device_matches = get_all_files_by_pattern(block_directory_pattern)
    if len(block_device_matches) == 0:
        raise FailedPciDeviceDetection(
            "No devices found for pattern " + block_directory_pattern
        )
    elif len(block_device_matches) > 1:
        raise FailedPciDeviceDetection(
            "Found more than one device for pattern"
            + block_directory_pattern
            + " : "
            + str(block_device_matches)
        )

    devices = get_directories(block_device_matches[0])
    if not devices or len(devices) == 0:
        raise FailedPciDeviceDetection(
            "No device exist under "
            + block_directory_pattern
            + " for pci device '"
            + pci_address
            + "'"
        )
    elif len(devices) > 1:
        raise FailedPciDeviceDetection(
            "Multiple devices are dected "
            + str(devices)
            + " for pci address '"
            + pci_address
            + "'"
        )
    device_path = os.path.join("/dev", devices[0])
    if not os.path.exists(device_path):
        raise FailedPciDeviceDetection("Device " + device_path + " does not exist")

    return device_path
