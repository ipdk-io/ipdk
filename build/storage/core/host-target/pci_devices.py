# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import os
import re
import glob


pci_validator = re.compile(
    r"[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-1]{1}[0-9a-fA-F]{1}\.[0-7]{1}"
)


class PciAddress:
    @staticmethod
    def _validate_pci_address(pci_address: str) -> bool:
        return pci_validator.search(pci_address) != None

    @staticmethod
    def _parse_pci_address(pci_address: str) -> tuple[str, str, str, str]:
        split_pci_address = pci_address.replace(".", ":").split(":")
        split_pci_address.reverse()
        function = split_pci_address[0].strip()
        device = split_pci_address[1].strip()
        bus = split_pci_address[2].strip()
        domain = split_pci_address[3].strip()
        return (domain, bus, device, function)

    def __init__(self, pci_address: str) -> None:
        if not pci_address or not PciAddress._validate_pci_address(pci_address):
            raise InvalidPciAddress(str(pci_address) + " is invalid")
        (
            self.domain,
            self.bus,
            self.device,
            self.function,
        ) = PciAddress._parse_pci_address(pci_address.lower())

    def get_bus_device_function_address(self) -> str:
        return self.bus + ":" + self.device + "." + self.function

    def get_full_address(self) -> str:
        return self.domain + ":" + self.get_bus_device_function_address()

    def __str__(self) -> str:
        return self.get_full_address()


def get_directories(path: str) -> list[str]:
    unused0, dirs, unused1 = next(os.walk(path))
    return dirs


def get_all_files_by_pattern(pattern: str) -> list[str]:
    return glob.glob(pattern)


class InvalidPciAddress(ValueError):
    pass


class FailedPciDeviceDetection(RuntimeError):
    pass


def get_virtio_blk_path_by_pci_address(addr: PciAddress) -> str:
    block_directory_pattern = os.path.join(
        os.path.join("/sys/bus/pci/devices", str(addr).lower()), "virtio*/block"
    )
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
            + str(addr)
            + "'"
        )
    elif len(devices) > 1:
        raise FailedPciDeviceDetection(
            "Multiple devices are detected "
            + str(devices)
            + " for pci address '"
            + str(addr)
            + "'"
        )
    device_path = os.path.join("/dev", devices[0])
    if not os.path.exists(device_path):
        raise FailedPciDeviceDetection("Device " + device_path + " does not exist")

    return device_path
