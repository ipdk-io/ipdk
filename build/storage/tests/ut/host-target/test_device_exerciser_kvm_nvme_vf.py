#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os
import test_device_exerciser_kvm_nvme

from device_exerciser_kvm import *
from device_exerciser_if import *
from helpers.file_helpers import read_file, write_file

default_pf_pci_address = "0000:af:00.1"
default_pf_sma_handle = "0.0"


# KVM case does not support VFs for NVMe
# Create a fake classes to check the vf flow
class FakeSmaHandleWithVfSupport(SmaHandle):
    def __init__(self, device_handle) -> None:
        elements = device_handle.split(".")
        self._physical_id = int(elements[0])
        self._virtual_id = int(elements[1])

    def is_virtual(self) -> bool:
        if self._virtual_id == 0:
            return False
        return True

    def get_pci_address(self) -> PciAddress:
        if self.is_virtual():
            device = hex((self._virtual_id // 8 % 32))[2:].zfill(2)
            function = hex(self._virtual_id % 8)[2:].zfill(1)
            return PciAddress(f"0000:B0:{device}.{function}")
        else:
            return PciAddress(default_pf_pci_address)

    def get_protocol(self) -> str:
        return NVME_PROTOCOL


class FakeDeviceExerciserWithVfSupport(DeviceExerciserKvm):
    def _create_sma_handle(self, device_handle: str) -> SmaHandle:
        return FakeSmaHandleWithVfSupport(device_handle)


class DeviceExerciserNvmeVfTest(test_device_exerciser_kvm_nvme.DeviceExerciserNvmeTest):
    def setUp(self):
        super().setUp()
        self.device_exerciser = self._create_test_device_exerciser()

    def _create_test_device_exerciser(self, wait=lambda x: None):
        return FakeDeviceExerciserWithVfSupport(
            {
                self.nvme_protocol_name: self.stub_get_nvme_path,
            },
            self.stub_run_fio,
            wait,
            self.sys_fs.get_read_file_wrapper(),
            self.sys_fs.get_write_file_wrapper(),
        )

    def test_successfully_plugged_nvme_device(self):
        self.sys_fs.create_pci_device_with_bound_driver_and_enabled_sriov(
            default_pf_pci_address, self.max_number_of_vfs
        )

        vf_sma_handle = "0.1"
        pci_addr = str(FakeSmaHandleWithVfSupport(vf_sma_handle).get_pci_address())

        self.device_exerciser.plug_device(vf_sma_handle)

        self.assertEqual(read_file(self.sys_fs.get_bind_path()), pci_addr)
        self.assertEqual(read_file(self.sys_fs.get_enable_path(pci_addr)), "1")

    def test_successfully_unplugged_nvme_device(self):
        self.sys_fs.create_pci_device_with_bound_driver_and_enabled_sriov(
            default_pf_pci_address, self.max_number_of_vfs
        )
        vf_sma_handle = "0.1"
        pci_addr = str(FakeSmaHandleWithVfSupport(vf_sma_handle).get_pci_address())
        self.device_exerciser.plug_device(vf_sma_handle)

        self.device_exerciser.unplug_device(vf_sma_handle)

        self.assertEqual(read_file(self.sys_fs.get_unbind_path()), pci_addr)
        self.assertFalse(os.path.exists(self.sys_fs.get_bound_device_path(pci_addr)))

    def test_cannot_unplug_pf_with_bound_vf(self):
        self.sys_fs.create_pci_device_with_bound_driver_and_enabled_sriov(
            default_pf_pci_address, self.max_number_of_vfs
        )
        device_exerciser = self._create_test_device_exerciser()
        vf_sma_handle = "0.1"

        self.device_exerciser.plug_device(vf_sma_handle)

        with self.assertRaises(DeviceExerciserError):
            device_exerciser.unplug_device(default_pf_sma_handle)
