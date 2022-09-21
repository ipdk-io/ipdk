# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import fio_runner
import copy
import os
import glob
import logging
from typing import Callable
from device_exerciser_if import DeviceExerciserIf
from fio_args import FioArgs
from device_exerciser_if import *
from volume import VolumeId
from pci_devices import (
    PciAddress,
    get_nvme_volumes,
    get_virtio_blk_volume,
)


VIRTIO_BLK_PROTOCOL = "virtio_blk"
NVME_PROTOCOL = "nvme"


class SmaHandleError(ValueError):
    pass


class DeviceExerciserKvm(DeviceExerciserIf):
    def __init__(
        self,
        volume_detectors={
            VIRTIO_BLK_PROTOCOL: get_virtio_blk_volume,
            NVME_PROTOCOL: get_nvme_volumes,
        },
        fio_runner=fio_runner.run_fio,
    ) -> None:
        self._volume_detectors = volume_detectors
        self._fio_runner = fio_runner

    class _SmaHandle:
        def get_protocol(self) -> str:
            raise NotImplementedError()

        def get_device_id(self) -> str:
            raise NotImplementedError()

    class _KvmSmaHandle(_SmaHandle):
        def __init__(self, sma_handle: str) -> None:
            if not sma_handle:
                raise SmaHandleError("SMA handle cannot be empty")
            self._protocol = self._parse_protocol(sma_handle)
            self._device_id = self._parse_device_id(sma_handle)

        def get_protocol(self) -> str:
            return self._protocol

        def get_device_id(self) -> str:
            return self._device_id

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

    class _KvmStorageDevice:
        def __init__(
            self, device_id: str, volume_detector: Callable, fio_runner: Callable
        ) -> None:
            self._find_volumes = volume_detector
            self._fio_runner = fio_runner
            self._device_id = device_id

        def run_fio_on_volumes(self, fio_args: FioArgs, volume_ids: set[VolumeId]):
            pci_addr = self._find_pci_addr(self._device_id)
            volumes = self._find_volumes(pci_addr, volume_ids)
            fio_args = copy.deepcopy(fio_args)
            fio_args.add_volumes_to_exercise(volumes)
            return self._fio_runner(fio_args)

        def _find_pci_addr(self, device_id: str):
            raise NotImplementedError()

    class _KvmVirtioBlkDevice(_KvmStorageDevice):
        def __init__(
            self, device_id: str, volume_detector: Callable, fio_runner: Callable
        ) -> None:
            self.MAX_NUMBER_OF_DEVICES_ON_BUS = 32
            super().__init__(device_id, volume_detector, fio_runner)

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
            bus = int(physical_id / self.MAX_NUMBER_OF_DEVICES_ON_BUS) + FIRST_IPDK_BUS
            if bus > 0xFF:
                raise SmaHandleError(
                    f"Physical_id '{physical_id}' exceeds number of buses"
                )
            return bus

        def _calculate_corresponding_device(self, physical_id: int):
            return physical_id % self.MAX_NUMBER_OF_DEVICES_ON_BUS

    class _KvmNvmeDevice(_KvmStorageDevice):
        def __init__(
            self, device_id: str, volume_detector: Callable, fio_runner: Callable
        ) -> None:
            super().__init__(device_id, volume_detector, fio_runner)

        def _find_pci_addr(self, device_id: str) -> PciAddress:
            subsysnqn = device_id
            nvme_devices = glob.glob("/sys/bus/pci/devices/*/nvme/nvme*")
            for nvme_device_path in nvme_devices:
                if self._get_subsysnqn(nvme_device_path) == subsysnqn:
                    return self._get_nvme_device_pci_addr(nvme_device_path)

            raise DeviceExerciserError(f"No nvme device with subsysnqn '{subsysnqn}'")

        def _get_subsysnqn(self, nvme_device_path: str) -> str:
            subsysnqn_file = os.path.join(nvme_device_path, "subsysnqn")
            subsysnqn_file_value = ""
            with open(subsysnqn_file) as f:
                subsysnqn_file_value = f.read().rstrip()
                logging.debug(f"Found nvme device with nqn {subsysnqn_file_value}")
            return subsysnqn_file_value

        def _get_nvme_device_pci_addr(self, nvme_device_path: str) -> PciAddress:
            return PciAddress(
                os.path.basename(os.path.dirname(os.path.dirname(nvme_device_path)))
            )

    def run_fio(
        self, device_handle: str, volume_ids: set[VolumeId], fio_args: FioArgs
    ) -> str:
        sma_handle = self._KvmSmaHandle(device_handle)
        storage_device = self._create_storage_device(sma_handle)
        return storage_device.run_fio_on_volumes(fio_args, volume_ids)

    def _create_storage_device(self, sma_handle: _SmaHandle) -> _KvmStorageDevice:
        if sma_handle.get_protocol() == VIRTIO_BLK_PROTOCOL:
            return self._KvmVirtioBlkDevice(
                sma_handle.get_device_id(),
                self._volume_detectors[sma_handle.get_protocol()],
                self._fio_runner,
            )
        elif sma_handle.get_protocol() == NVME_PROTOCOL:
            return self._KvmNvmeDevice(
                sma_handle.get_device_id(),
                self._volume_detectors[sma_handle.get_protocol()],
                self._fio_runner,
            )
        else:
            raise DeviceExerciserError(
                "Unsupported protocol '" + sma_handle.get_protocol() + "'"
            )
