# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
from typing import Callable

from pci import PciAddress

from devices import StoragePcieDevice
from drivers import VirtioPciDriver


class VirtioBlkDevice(StoragePcieDevice):
    def __init__(
        self,
        pci_addr: PciAddress,
        driver: VirtioPciDriver,
        volume_detector: Callable,
        fio_runner: Callable,
        wait: Callable,
    ) -> None:
        super().__init__(pci_addr, driver, volume_detector, fio_runner, wait)
