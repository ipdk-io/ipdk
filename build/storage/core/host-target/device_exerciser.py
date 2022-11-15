# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import fio_runner
import logging
import time
from device_exerciser_if import DeviceExerciserIf
from helpers.fio_args import FioArgs
from device_exerciser_if import *
from volumes import VolumeId
from volumes import (
    get_nvme_volumes,
    get_virtio_blk_volume,
)
from sma_handle import SmaHandle, SmaHandleError
from helpers.file_helpers import read_file, write_file

from devices import StoragePcieDevice
from devices import VirtioBlkDevice
from devices import NvmePfDevice, NvmeVfDevice
from devices import DeviceError
from drivers import VirtioPciDriver
from drivers import NvmeDriver
from drivers import DriverError


VIRTIO_BLK_PROTOCOL = "virtio_blk"
NVME_PROTOCOL = "nvme"


class DeviceExerciser(DeviceExerciserIf):
    def __init__(
        self,
        volume_detectors={
            VIRTIO_BLK_PROTOCOL: get_virtio_blk_volume,
            NVME_PROTOCOL: get_nvme_volumes,
        },
        fio_runner=fio_runner.run_fio,
        wait=time.sleep,
        read_file=read_file,
        write_file=write_file,
    ) -> None:
        self._volume_detectors = volume_detectors
        self._fio_runner = fio_runner
        self._wait = wait
        self._read_file = read_file
        self._write_file = write_file

    def _create_sma_handle(self, device_handle: str) -> SmaHandle:
        raise NotImplementedError()

    def run_fio(
        self, device_handle: str, volume_ids: set[VolumeId], fio_args: FioArgs
    ) -> str:
        storage_device = self._create_storage_device(device_handle)
        return storage_device.run_fio_on_volumes(fio_args, volume_ids)

    def _create_storage_device(self, device_handle: str) -> StoragePcieDevice:
        sma_handle = self._create_sma_handle(device_handle)
        logging.info("SMA Handle object is created")
        if sma_handle.get_protocol() == VIRTIO_BLK_PROTOCOL:
            logging.info(f"Creating virtio blk device for {device_handle}")
            return VirtioBlkDevice(
                sma_handle.get_pci_address(),
                VirtioPciDriver(
                    wait=self._wait,
                    read_file=self._read_file,
                    write_file=self._write_file,
                ),
                self._volume_detectors[sma_handle.get_protocol()],
                self._fio_runner,
                self._wait,
            )
        elif sma_handle.get_protocol() == NVME_PROTOCOL:
            logging.info(f"Creating NVMe device")
            if sma_handle.is_virtual():
                logging.info(f"Creating NVMe vf device for {device_handle}")
                return NvmeVfDevice(
                    sma_handle.get_pci_address(),
                    NvmeDriver(
                        wait=self._wait,
                        read_file=self._read_file,
                        write_file=self._write_file,
                    ),
                    self._volume_detectors[sma_handle.get_protocol()],
                    self._fio_runner,
                    self._wait,
                )
            else:
                logging.info(f"Creating NVMe pf device for {device_handle}")
                return NvmePfDevice(
                    sma_handle.get_pci_address(),
                    NvmeDriver(
                        wait=self._wait,
                        read_file=self._read_file,
                        write_file=self._write_file,
                    ),
                    self._volume_detectors[sma_handle.get_protocol()],
                    self._fio_runner,
                    self._wait,
                )
        else:
            raise DeviceExerciserError(
                "Unsupported protocol '" + sma_handle.get_protocol() + "'"
            )

    def plug_device(self, device_handle: str) -> None:
        logging.info(f"plug device: {device_handle}")
        try:
            device = self._create_storage_device(device_handle)

            if not device.wait_device_created_by_ipu():
                raise DeviceExerciserError(f"Device {device_handle} was not created.")

            logging.info(f"Device for {device_handle} is created")
            if device.wait_automatically_plugged():
                logging.info(f"Device {device_handle} was automatically plugged")
            else:
                logging.info("Device is not plugged. Start plug")
                device.plug()
                logging.info("End plug")

        except (DriverError, DeviceError, SmaHandleError) as ex:
            raise DeviceExerciserError(str(ex))

    def unplug_device(self, device_handle: str) -> None:
        logging.info(f"unplug device: {device_handle}")
        try:
            device = self._create_storage_device(device_handle)
            if device.is_plugged():
                logging.info("Device is plugged. Start unplug")
                device.unplug()
                logging.info("End unplug")
        except (DriverError, DeviceError, SmaHandleError) as ex:
            raise DeviceExerciserError(str(ex))
