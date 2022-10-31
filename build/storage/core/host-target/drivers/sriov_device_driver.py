# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import os
import logging
import glob
from typing import Callable

from pci import PciAddress

from drivers import DeviceDriver


class SriovDeviceDriver(DeviceDriver):
    def __init__(
        self,
        driver_name: str,
        wait_sec: int,
        wait: Callable,
        read_file: Callable,
        write_file: Callable,
    ) -> None:
        super().__init__(driver_name, wait_sec, wait, read_file, write_file)

    def _get_bound_device_path(self, pci_addr: PciAddress) -> str:
        return os.path.join(self._get_driver_path(), str(pci_addr))

    def _get_sriov_drivers_autoprobe_path(self, pci_addr: PciAddress) -> str:
        return os.path.join(
            self._get_bound_device_path(pci_addr), "sriov_drivers_autoprobe"
        )

    def _get_sriov_totalvfs_path(self, pci_addr: PciAddress) -> str:
        return os.path.join(self._get_bound_device_path(pci_addr), "sriov_totalvfs")

    def _get_sriov_numvfs_path(self, pci_addr: PciAddress) -> str:
        return os.path.join(self._get_bound_device_path(pci_addr), "sriov_numvfs")

    def is_sriov_supported(self, pci_addr: PciAddress) -> bool:
        sriov_drivers_autoprobe_path = self._get_sriov_drivers_autoprobe_path(pci_addr)
        sriov_totalvfs_path = self._get_sriov_totalvfs_path(pci_addr)
        sriov_numvfs_path = self._get_sriov_numvfs_path(pci_addr)

        if (
            os.path.exists(sriov_totalvfs_path)
            and os.path.exists(sriov_drivers_autoprobe_path)
            and os.path.exists(sriov_numvfs_path)
        ):
            return True
        return False

    def is_sriov_enabled(self, pci_addr: PciAddress) -> bool:
        sriov_totalvfs_path = self._get_sriov_totalvfs_path(pci_addr)
        sriov_numvfs_path = self._get_sriov_numvfs_path(pci_addr)

        total_vfs = int(self._read_file(sriov_totalvfs_path))
        current_numvfs = int(self._read_file(sriov_numvfs_path))
        logging.info(f"total vfs: {total_vfs}, current_numvfs: {current_numvfs}")
        if current_numvfs != total_vfs:
            return False

        sriov_drivers_autoprobe_path = self._get_sriov_drivers_autoprobe_path(pci_addr)
        is_autoprobe_enabled = int(self._read_file(sriov_drivers_autoprobe_path))
        logging.info(f"is_autoprobe_enabled: {is_autoprobe_enabled}")
        if is_autoprobe_enabled != 0:
            return False
        return True

    def enable_sriov(self, pci_addr: PciAddress) -> None:
        sriov_drivers_autoprobe_path = self._get_sriov_drivers_autoprobe_path(pci_addr)
        self._write_file(sriov_drivers_autoprobe_path, "0")

        sriov_totalvfs_path = self._get_sriov_totalvfs_path(pci_addr)
        total_vfs = int(self._read_file(sriov_totalvfs_path))
        sriov_numvfs_path = self._get_sriov_numvfs_path(pci_addr)
        self._write_file(sriov_numvfs_path, total_vfs)

    def disable_sriov(self, pci_addr: PciAddress) -> None:
        sriov_numvfs_path = self._get_sriov_numvfs_path(pci_addr)
        self._write_file(sriov_numvfs_path, "0")

    def are_vfs_enabled(self, pci_addr: PciAddress) -> bool:
        vf_enables = glob.glob(
            os.path.join(self._get_pci_device_path(pci_addr), "virtfn*/enable")
        )
        if len(vf_enables) == 0:
            return False

        for vf_enable in vf_enables:
            if self._read_file(vf_enable).strip() == "1":
                logging.info(f"Unplugged vf {vf_enable}")
                return True
        return False
