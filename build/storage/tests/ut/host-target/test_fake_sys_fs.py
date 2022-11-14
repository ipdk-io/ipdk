#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#


import os
from fake_pci_sys_fs import FakePciSysFs
from pci import PciAddress
from pyfakefs.fake_filesystem_unittest import TestCase
from helpers.file_helpers import read_file


class DeviceExerciserTest(TestCase):
    def setUp(self):
        self.setUpPyfakefs()
        self.sys_fs = FakePciSysFs(self.fs, "nvme")
        self.pci_addr = PciAddress("0000:aa:00.1")

    def tearDown(self):
        pass

    def test_pci_device_is_created(self):
        self.sys_fs.create_pci_device(self.pci_addr)

        self.assertTrue(os.path.isfile(self.sys_fs.get_bind_path()))
        self.assertTrue(os.path.isfile(self.sys_fs.get_unbind_path()))
        self.assertEqual(
            read_file(self.sys_fs.get_driver_override_path(self.pci_addr)), "(null)"
        )
        self.assertEqual(read_file(self.sys_fs.get_enable_path(self.pci_addr)), "0")
        self.assertFalse(
            os.path.exists(self.sys_fs.get_bound_device_path(self.pci_addr))
        )

    def test_pci_device_with_sriov_is_created(self):
        max_vfs = 2
        self.sys_fs.create_pci_device_with_sriov(self.pci_addr, max_vfs)

        self.assertTrue(os.path.isfile(self.sys_fs.get_bind_path()))
        self.assertTrue(os.path.isfile(self.sys_fs.get_unbind_path()))
        self.assertEqual(
            read_file(self.sys_fs.get_driver_override_path(self.pci_addr)), "(null)"
        )
        self.assertEqual(read_file(self.sys_fs.get_enable_path(self.pci_addr)), "0")
        self.assertEqual(
            read_file(self.sys_fs.get_sriov_drivers_autoprobe_path(self.pci_addr)), "1"
        )
        self.assertEqual(
            read_file(self.sys_fs.get_sriov_totalvfs_path(self.pci_addr)), str(max_vfs)
        )
        self.assertEqual(
            read_file(self.sys_fs.get_sriov_numvfs_path(self.pci_addr)), "0"
        )
        self.assertFalse(
            os.path.exists(self.sys_fs.get_bound_device_path(self.pci_addr))
        )

    def test_bound_pci_device_with_enabled_sriov(self):
        max_vfs = 2
        self.sys_fs.create_pci_device_with_bound_driver_and_enabled_sriov(
            self.pci_addr, max_vfs
        )

        # check pf is initialized
        self.assertTrue(os.path.isfile(self.sys_fs.get_bind_path()))
        self.assertTrue(os.path.isfile(self.sys_fs.get_unbind_path()))
        self.assertEqual(
            read_file(self.sys_fs.get_driver_override_path(self.pci_addr)), "(null)"
        )
        self.assertEqual(read_file(self.sys_fs.get_enable_path(self.pci_addr)), "1")
        self.assertEqual(
            read_file(self.sys_fs.get_sriov_drivers_autoprobe_path(self.pci_addr)), "0"
        )
        self.assertEqual(
            read_file(self.sys_fs.get_sriov_totalvfs_path(self.pci_addr)), str(max_vfs)
        )
        self.assertEqual(
            read_file(self.sys_fs.get_sriov_numvfs_path(self.pci_addr)), str(max_vfs)
        )
        self.assertEqual(
            read_file(f"{self.sys_fs.get_bound_device_path(self.pci_addr)}/enable"),
            "1",
        )

        # check vfs are created and initialized
        self.assertEqual(
            read_file(f"{self.sys_fs.get_virtfn_path(self.pci_addr, 1)}/enable"), "0"
        )

        self.assertEqual(
            read_file(
                f"{self.sys_fs.get_virtfn_path(self.pci_addr, 1)}/driver_override"
            ),
            "(null)",
        )

        # pf is accessible as link from vf
        self.assertEqual(
            read_file(f"{self.sys_fs.get_virtfn_path(self.pci_addr, 1)}/physfn/enable"),
            "1",
        )

    def test_device_is_bound_over_sysfs(self):
        self.sys_fs.create_pci_device(self.pci_addr)
        write = self.sys_fs.get_write_file_wrapper()

        write(self.sys_fs.get_bind_path(), self.pci_addr)

        self.assertEqual(
            read_file(f"{self.sys_fs.get_bound_device_path(self.pci_addr)}/enable"),
            "1",
        )

    def test_device_is_bound_over_method(self):
        self.sys_fs.create_pci_device(self.pci_addr)

        self.sys_fs.bind_pci_device_to_driver(self.pci_addr)

        self.assertEqual(
            read_file(f"{self.sys_fs.get_bound_device_path(self.pci_addr)}/enable"),
            "1",
        )

    def test_device_is_unbound_over_sysfs(self):
        self.sys_fs.create_pci_device(self.pci_addr)
        write = self.sys_fs.get_write_file_wrapper()
        write(self.sys_fs.get_bind_path(), self.pci_addr)

        write(self.sys_fs.get_unbind_path(), self.pci_addr)

        self.assertEqual(read_file(self.sys_fs.get_enable_path(self.pci_addr)), "0")
        self.assertFalse(
            os.path.exists(self.sys_fs.get_bound_device_path(self.pci_addr))
        )

    def test_device_is_unbound_over_method(self):
        self.sys_fs.create_pci_device(self.pci_addr)
        self.sys_fs.bind_pci_device_to_driver(self.pci_addr)

        self.sys_fs.unbind_pci_device_to_driver(self.pci_addr)
        self.assertEqual(read_file(self.sys_fs.get_enable_path(self.pci_addr)), "0")
        self.assertFalse(
            os.path.exists(self.sys_fs.get_bound_device_path(self.pci_addr))
        )

    def test_device_is_not_bound_with_dedicated_flag(self):
        self.sys_fs.create_pci_device(self.pci_addr)
        write = self.sys_fs.get_write_file_wrapper()

        self.sys_fs.do_not_bind_device_to_driver()
        write(self.sys_fs.get_bind_path(), self.pci_addr)

        self.assertFalse(
            os.path.exists(self.sys_fs.get_bound_device_path(self.pci_addr))
        )

    def test_device_is_not_unbound_with_dedicated_flag(self):
        self.sys_fs.create_pci_device(self.pci_addr)
        write = self.sys_fs.get_write_file_wrapper()
        write(self.sys_fs.get_bind_path(), self.pci_addr)

        self.sys_fs.do_not_unbind_device_from_driver()
        write(self.sys_fs.get_unbind_path(), self.pci_addr)

        self.assertTrue(
            os.path.exists(self.sys_fs.get_bound_device_path(self.pci_addr))
        )
