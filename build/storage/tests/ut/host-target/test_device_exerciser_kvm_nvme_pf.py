#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os


from device_exerciser_kvm import *
from device_exerciser_if import *
import test_device_exerciser_kvm_nvme


class DeviceExerciserNvmePfTest(test_device_exerciser_kvm_nvme.DeviceExerciserNvmeTest):
    def setUp(self):
        super().setUp()
        self.device_exerciser = self._create_test_device_exerciser()

    def _create_test_device_exerciser(self, wait=lambda x: None):
        return DeviceExerciserKvm(
            {
                self.nvme_protocol_name: self.stub_get_nvme_path,
            },
            self.stub_run_fio,
            wait,
            self.sys_fs.get_read_file_wrapper(),
            self.sys_fs.get_write_file_wrapper(),
        )

    def test_nvme_sma_handle_parsed_to_correct_pci_address(self):
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-17"
        pci_addr = "0000:01:11.0"
        self.device_exerciser.run_fio(f"nvme:{subsysnqn}", {}, self.fio_args)
        self.assertEqual(self.parsed_pci_addr, pci_addr)

    def test_successfully_plugged_nvme_device(self):
        pci_addr = "0000:01:10.0"
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-16"
        sma_handle = f"nvme:{subsysnqn}"
        self.sys_fs.create_pci_device(pci_addr)

        self.device_exerciser.plug_device(sma_handle)

        self.assertEqual(read_file(self.sys_fs.get_bind_path()), pci_addr)
        self.assertEqual(read_file(self.sys_fs.get_enable_path(pci_addr)), "1")

    def test_successfully_plugged_nvme_device_with_multiple_tries(self):
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-16"
        pci_addr = "0000:01:10.0"
        sma_handle = f"nvme:{subsysnqn}"
        self.sys_fs.create_pci_device(pci_addr)
        self.sys_fs.do_not_bind_device_to_driver()

        def stub_wait(_):
            if not read_file(self.sys_fs.get_bind_path()):
                return

            if stub_wait.counter == 2:
                self.sys_fs.bind_pci_device_to_driver(pci_addr)
            stub_wait.counter = stub_wait.counter + 1

        stub_wait.counter = 0
        device_exerciser = self._create_test_device_exerciser(stub_wait)

        device_exerciser.plug_device(sma_handle)
        self.assertEqual(read_file(self.sys_fs.get_bind_path()), pci_addr)
        self.assertEqual(read_file(self.sys_fs.get_enable_path(pci_addr)), "1")
        self.assertTrue(stub_wait.counter > 0)

    def test_nvme_pf_appears_in_sys_fs_with_multiple_tries(self):
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-16"
        pci_addr = "0000:01:10.0"
        sma_handle = f"nvme:{subsysnqn}"

        def stub_wait(_):
            if stub_wait.counter == 2:
                self.sys_fs.create_pci_device(pci_addr)
            stub_wait.counter = stub_wait.counter + 1

        stub_wait.counter = 0

        device_exerciser = self._create_test_device_exerciser(stub_wait)

        device_exerciser.plug_device(sma_handle)
        self.assertEqual(read_file(self.sys_fs.get_bind_path()), pci_addr)
        self.assertEqual(read_file(self.sys_fs.get_enable_path(pci_addr)), "1")
        self.assertTrue(os.path.exists(self.sys_fs.get_pci_device_path(pci_addr)))
        self.assertTrue(stub_wait.counter > 0)

    def test_unsuccessfully_plugged_nvme_device(self):
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-16"
        pci_addr = "0000:01:10.0"
        sma_handle = f"nvme:{subsysnqn}"
        self.sys_fs.create_pci_device(pci_addr)
        self.sys_fs.do_not_bind_device_to_driver()

        with self.assertRaises(DeviceExerciserError):
            self.device_exerciser.plug_device(sma_handle)

        self.assertEqual(read_file(self.sys_fs.get_bind_path()), pci_addr)
        self.assertEqual(read_file(self.sys_fs.get_enable_path(pci_addr)), "0")

    def test_successfully_unplugged_nvme_pf(self):
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-16"
        pci_addr = "0000:01:10.0"
        sma_handle = f"nvme:{subsysnqn}"
        self.sys_fs.create_pci_device_with_bound_driver_and_enabled_sriov(
            pci_addr, self.max_number_of_vfs
        )

        self.device_exerciser.unplug_device(sma_handle)

        self.assertEqual(read_file(self.sys_fs.get_unbind_path()), pci_addr)
        self.assertFalse(os.path.exists(self.sys_fs.get_bound_device_path(pci_addr)))

    def test_enable_sriov_when_supported_at_plug(self):
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-16"
        pci_addr = "0000:01:10.0"
        sma_handle = f"nvme:{subsysnqn}"
        self.sys_fs.create_pci_device_with_sriov(pci_addr, self.max_number_of_vfs)

        self.device_exerciser.plug_device(sma_handle)

        self.assertEqual(
            read_file(self.sys_fs.get_sriov_drivers_autoprobe_path(pci_addr)), "0"
        )
        self.assertEqual(
            read_file(self.sys_fs.get_sriov_numvfs_path(pci_addr)),
            str(self.max_number_of_vfs),
        )

    def test_enable_sriov_when_supported_and_driver_is_already_bound(self):
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-16"
        pci_addr = "0000:01:10.0"
        sma_handle = f"nvme:{subsysnqn}"
        self.sys_fs.create_pci_device_with_sriov(pci_addr, self.max_number_of_vfs)
        self.sys_fs.bind_pci_device_to_driver(pci_addr)

        self.device_exerciser.plug_device(sma_handle)

        self.assertEqual(
            read_file(self.sys_fs.get_sriov_drivers_autoprobe_path(pci_addr)), "0"
        )
        self.assertEqual(
            read_file(self.sys_fs.get_sriov_numvfs_path(pci_addr)),
            str(self.max_number_of_vfs),
        )

    def test_disable_sriov_when_supported_at_unplug(self):
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-16"
        pci_addr = "0000:01:10.0"
        sma_handle = f"nvme:{subsysnqn}"
        self.sys_fs.create_pci_device_with_bound_driver_and_enabled_sriov(
            pci_addr, self.max_number_of_vfs
        )

        self.device_exerciser.unplug_device(sma_handle)

        self.assertEqual(read_file(self.sys_fs.get_sriov_numvfs_path(pci_addr)), "0")
