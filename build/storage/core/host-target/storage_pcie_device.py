# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import os
import copy

import copy

from typing import Callable
from pci_devices import PciAddress
from device_driver import DeviceDriver
from fio_args import FioArgs
from volume import VolumeId


class StoragePcieDevice:
    def __init__(
        self,
        pci_addr: PciAddress,
        driver: DeviceDriver,
        volume_detector: Callable,
        fio_runner: Callable,
        wait: Callable,
    ) -> None:
        self._pci_addr = pci_addr
        self._driver = driver
        self._find_volumes = volume_detector
        self._fio_runner = fio_runner
        self._wait = wait
        self._wait_step = 0.1
        self._wait_number_of_steps = 30

    def run_fio_on_volumes(self, fio_args: FioArgs, volume_ids: set[VolumeId]) -> str:
        volumes = self._find_volumes(self._pci_addr, volume_ids)
        fio_args = copy.deepcopy(fio_args)
        fio_args.add_volumes_to_exercise(volumes)
        return self._fio_runner(fio_args)

    def exists(self) -> bool:
        return os.path.exists(f"/sys/bus/pci/devices/{self._pci_addr}")

    def wait_device_created_by_ipu(self) -> bool:
        for _ in range(self._wait_number_of_steps):
            if self.exists():
                return True
            self._wait(self._wait_step)
        return False

    def wait_automatically_plugged(self) -> bool:
        for _ in range(self._wait_number_of_steps):
            if self.is_plugged():
                return True
            self._wait(self._wait_step)
        return False

    def is_plugged(self) -> bool:
        return self._driver.is_bound(self._pci_addr)

    def plug(self) -> None:
        if not self._driver.is_bound(self._pci_addr):
            self._driver.bind(self._pci_addr)

    def unplug(self) -> None:
        if self._driver.is_bound(self._pci_addr):
            self._driver.unbind(self._pci_addr)
