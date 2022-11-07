# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import re


class InvalidPciAddress(ValueError):
    pass


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
