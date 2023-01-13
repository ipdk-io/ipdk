# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import os
import logging
from typing import Callable

from pci import PciAddress
from helpers.file_helpers import WriteAndRestoreFileContent


class DriverError(RuntimeError):
    pass


class DeviceDriver:
    def __init__(
        self,
        driver_name: str,
        wait_sec: int,
        wait: Callable,
        read_file: Callable,
        write_file: Callable,
    ) -> None:
        self._driver_name = driver_name
        self._wait_sec = wait_sec
        self._wait = wait
        self._read_file = read_file
        self._write_file = write_file

    def is_bound(self, pci_addr: PciAddress) -> bool:
        if os.path.exists(f"/sys/bus/pci/drivers/{self._driver_name}/{pci_addr}"):
            return True
        return False

    def bind(self, pci_addr: PciAddress) -> None:
        driver_override_path = self._get_driver_override_path(pci_addr)
        with WriteAndRestoreFileContent(driver_override_path) as driver_override:
            driver_override.write_tmp_content(self._driver_name)
            nvme_driver_bind = os.path.join(self._get_driver_path(), "bind")
            try:
                self._write_file(nvme_driver_bind, pci_addr)
            except OSError:
                pass

        for _ in range(self._wait_sec):
            if self.is_bound(pci_addr):
                return
            self._wait(1)
        logging.error(
            f"Device '{pci_addr}' cannot be bound to '{self._driver_name}' driver"
        )
        raise DriverError(f"Device cannot be bound to driver")

    def unbind(self, pci_addr: PciAddress) -> None:
        nvme_driver_unbind = os.path.join(self._get_driver_path(), "unbind")
        self._write_file(nvme_driver_unbind, pci_addr)

        for _ in range(self._wait_sec):
            if not self.is_bound(pci_addr):
                return
            self._wait(1)
        logging.error(
            f"Device '{pci_addr}' cannot be unbound from '{self._driver_name}' driver"
        )
        raise DriverError(f"Device cannot be unbound from driver")

    def _get_driver_path(self) -> str:
        return f"/sys/bus/pci/drivers/{self._driver_name}/"

    def _get_pci_device_path(self, pci_addr: PciAddress) -> str:
        return os.path.join("/sys/bus/pci/devices/", str(pci_addr))

    def _get_driver_override_path(self, pci_addr: PciAddress) -> str:
        pci_device_path = self._get_pci_device_path(pci_addr)
        return os.path.join(pci_device_path, "driver_override")
