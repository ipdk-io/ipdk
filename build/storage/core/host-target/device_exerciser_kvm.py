# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from pci import PciAddress
from sma_handle import SmaHandle, SmaHandleError
from device_exerciser import *

MAX_NUMBER_OF_DEVICES_ON_BUS = 32


class KvmSmaHandle:
    def __init__(self, sma_handle: str) -> None:
        if not sma_handle:
            raise SmaHandleError("SMA handle cannot be empty")
        self._protocol = self._parse_protocol(sma_handle)
        device_id = self._parse_device_id(sma_handle)
        self._pci_address = self._find_pci_addr(device_id)

    def _parse_protocol(self, sma_handle: str) -> str:
        (
            protocol,
            _,
        ) = self._split_sma_handle_to_protocol_and_device_id(sma_handle)
        return protocol

    def _parse_device_id(self, sma_handle: str) -> str:
        (
            _,
            device_id,
        ) = self._split_sma_handle_to_protocol_and_device_id(sma_handle)
        return device_id

    def _split_sma_handle_to_protocol_and_device_id(
        self, sma_handle: str
    ) -> tuple[str, str]:
        PROTOCOL_SEPARATOR = ":"
        if PROTOCOL_SEPARATOR not in sma_handle:
            raise SmaHandleError(
                "Unsupported protocol separator in '" + sma_handle + "'"
            )
        return tuple(sma_handle.split(PROTOCOL_SEPARATOR, 1))

    def _find_pci_addr(self, device_id: str) -> PciAddress:
        physical_id = self._parse_physical_id(device_id)
        bus = self._calculate_corresponding_bus(physical_id)
        device = self._calculate_corresponding_device(physical_id)
        return PciAddress(f"0000:{bus:02x}:{device:02x}.0")

    def _parse_physical_id(self, device_id: str) -> int:
        PHYSICAL_ID_SEPARATOR = "-"
        if PHYSICAL_ID_SEPARATOR not in device_id:
            raise SmaHandleError(
                "Unsupported physical_id separator in '" + device_id + "'"
            )

        physical_id_str = device_id.split(PHYSICAL_ID_SEPARATOR)[-1]
        if not physical_id_str.isdigit():
            raise SmaHandleError(
                "Unsupported physical_id format '" + physical_id_str + "'"
            )

        physical_id = int(physical_id_str)
        return physical_id

    def _calculate_corresponding_bus(self, physical_id: int) -> int:
        FIRST_IPDK_BUS = 1
        bus = int(physical_id / MAX_NUMBER_OF_DEVICES_ON_BUS) + FIRST_IPDK_BUS
        if bus > 0xFF:
            raise SmaHandleError(f"Physical_id '{physical_id}' exceeds number of buses")
        return bus

    def _calculate_corresponding_device(self, physical_id: int) -> int:
        return physical_id % MAX_NUMBER_OF_DEVICES_ON_BUS

    def is_virtual(self) -> bool:
        return False

    def get_pci_address(self) -> PciAddress:
        return self._pci_address

    def get_protocol(self) -> str:
        return self._protocol


class DeviceExerciserKvm(DeviceExerciser):
    def _create_sma_handle(self, device_handle: str) -> SmaHandle:
        return KvmSmaHandle(device_handle)
