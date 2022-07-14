# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import fio_runner
from device_exerciser_if import *
from pci_devices import (
    InvalidPciAddress,
    PciAddress,
    get_virtio_blk_path_by_pci_address,
)


VIRTIO_BLK_PROTOCOL = "virtio_blk"
PROTOCOL_SEPARATOR = ":"
PHYSICAL_ID_SEPARATOR = "-"


class SmaHandleError(ValueError):
    pass


class DeviceExerciserKvm(DeviceExerciserIf):
    def __init__(
        self,
        device_detectors={VIRTIO_BLK_PROTOCOL: get_virtio_blk_path_by_pci_address},
        fio_runner=fio_runner.run_fio,
    ) -> None:
        self._device_detectors = device_detectors
        self._fio_runner = fio_runner

    class _SmaHandle:
        def get_protocol(self) -> str:
            raise NotImplementedError()

        def get_pci_address(self) -> PciAddress:
            raise NotImplementedError()

    class _KvmSmaHandle(_SmaHandle):
        def __init__(
            self,
            sma_handle: str,
        ) -> None:
            if not sma_handle:
                raise SmaHandleError("SMA handle cannot be empty")
            self._protocol = self._convert_sma_handle_to_protocol(sma_handle)
            pci_address = self._convert_sma_handle_to_pci_address(sma_handle)
            self._pci_address = PciAddress(pci_address)

        def get_protocol(self) -> str:
            return self._protocol

        def get_pci_address(self) -> PciAddress:
            return self._pci_address

        def _split_device_handle_to_protocol_and_plugin_device_handle(
            self, sma_handle: str
        ) -> tuple[str, str]:
            if PROTOCOL_SEPARATOR not in sma_handle:
                raise SmaHandleError(
                    "Unsupported protocol separator in '" + sma_handle + "'"
                )
            result = tuple(sma_handle.split(PROTOCOL_SEPARATOR))
            if len(result) != 2:
                raise SmaHandleError("Invalid handle format of '" + sma_handle + "'")
            return result

        def _convert_sma_handle_to_protocol(self, sma_handle: str) -> str:
            (
                protocol,
                unused_handle,
            ) = self._split_device_handle_to_protocol_and_plugin_device_handle(
                sma_handle
            )
            return protocol

        def _convert_sma_handle_to_pci_address(self, sma_handle: str) -> str:
            (
                unused_protocol,
                handle,
            ) = self._split_device_handle_to_protocol_and_plugin_device_handle(
                sma_handle
            )

            if PHYSICAL_ID_SEPARATOR not in handle:
                raise SmaHandleError(
                    "Unsupported physical_id separator in '" + handle + "'"
                )

            physical_id_str = handle.split(PHYSICAL_ID_SEPARATOR)[1]
            if not physical_id_str.isdigit():
                raise SmaHandleError(
                    "Unsupported physical_id format '" + physical_id_str + "'"
                )

            physical_id = int(physical_id_str)
            MAX_NUMBER_OF_DEVICES_ON_BUS = 32
            FIRST_IPDK_BUS = 1
            bus = int(physical_id / MAX_NUMBER_OF_DEVICES_ON_BUS) + FIRST_IPDK_BUS
            if bus > 0xFF:
                raise SmaHandleError(
                    "Physical_id '" + physical_id_str + "' exceeds number of buses"
                )
            device = physical_id % MAX_NUMBER_OF_DEVICES_ON_BUS
            return f"0000:{bus:02x}:{device:02x}.0".upper()

    def _create_sma_handle_from_str(self, device_handle: str) -> _SmaHandle:
        return self._KvmSmaHandle(device_handle)

    def run_fio(self, device_handle: str, fio_args: FioArgs) -> str:
        sma_handle = self._create_sma_handle_from_str(device_handle)

        if sma_handle.get_protocol() not in self._device_detectors:
            raise DeviceExerciserError(
                "Unsupported protocol '" + sma_handle.get_protocol() + "'"
            )

        device_path = self._device_detectors[sma_handle.get_protocol()](
            sma_handle.get_pci_address()
        )

        fio_args.add_argument("filename", device_path)
        return self._fio_runner(fio_args)
