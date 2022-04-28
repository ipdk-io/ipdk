#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os
from pci_devices import get_virtio_blk_path_by_pci_address
from pci_devices import InvalidPciAddress
from pci_devices import FailedPciDeviceDetection
from pyfakefs.fake_filesystem_unittest import TestCase


class PciDeviceTests(TestCase):
    def setUp(self):
        self.setUpPyfakefs()

    def test_get_device_by_pci_address(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_path_by_pci_address("0000:00:04.0")
        self.assertEqual(dev_path, "/dev/vda")

    def test_get_device_by_not_conventional_pci_address(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")

        with self.assertRaises(InvalidPciAddress) as ex:
            get_virtio_blk_path_by_pci_address("0000:00:04.9")
        with self.assertRaises(InvalidPciAddress) as ex:
            get_virtio_blk_path_by_pci_address("0000:00:20.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            get_virtio_blk_path_by_pci_address("0000:00:00:0")
        with self.assertRaises(InvalidPciAddress) as ex:
            get_virtio_blk_path_by_pci_address("0000:00.00.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            get_virtio_blk_path_by_pci_address("0:00.00.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            get_virtio_blk_path_by_pci_address("0000:0.00.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            get_virtio_blk_path_by_pci_address("0000:00.0.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            get_virtio_blk_path_by_pci_address("0000:00.00.01")

    def test_corner_bus_value(self):
        path = "/sys/devices/pci0000:FF/0000:FF:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_path_by_pci_address("0000:FF:04.0")
        self.assertEqual(dev_path, "/dev/vda")

    def test_corner_device_value(self):
        path = "/sys/devices/pci0000:00/0000:00:1F.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_path_by_pci_address("0000:00:1F.0")
        self.assertEqual(dev_path, "/dev/vda")

    def test_corner_function_value(self):
        path = "/sys/devices/pci0000:00/0000:00:04.7/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_path_by_pci_address("0000:00:04.7")
        self.assertEqual(dev_path, "/dev/vda")

    def test_multiple_domains(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/devices/pci0001:00/0001:00:04.0/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")

        dev_path = get_virtio_blk_path_by_pci_address("0001:00:04.0")
        self.assertEqual(dev_path, "/dev/vdb")

    def test_multiple_buses(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/devices/pci0000:01/0000:01:04.0/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")

        dev_path = get_virtio_blk_path_by_pci_address("0000:01:04.0")
        self.assertEqual(dev_path, "/dev/vdb")

    def test_multiple_devices(self):
        path = "/sys/devices/pci0000:00/0000:00:00.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/devices/pci0000:00/0000:00:01.0/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")

        dev_path = get_virtio_blk_path_by_pci_address("0000:00:01.0")
        self.assertEqual(dev_path, "/dev/vdb")

    def test_multiple_functions(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/devices/pci0000:00/0000:00:04.1/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")

        dev_path = get_virtio_blk_path_by_pci_address("0000:00:04.1")
        self.assertEqual(dev_path, "/dev/vdb")

    def test_no_block_device_exists(self):
        path_to_device = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block"
        self.fs.create_dir(path_to_device)
        with self.assertRaises(FailedPciDeviceDetection) as ex:
            get_virtio_blk_path_by_pci_address("0000:00:00.0")

    def test_multiple_block_devices_in_virtio_dir(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")
        with self.assertRaises(FailedPciDeviceDetection) as ex:
            get_virtio_blk_path_by_pci_address("0000:00:04.0")

    def test_multiple_block_devices_under_different_virtio_dirs(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")
        with self.assertRaises(FailedPciDeviceDetection) as ex:
            get_virtio_blk_path_by_pci_address("0000:00:04.0")

    def test_no_directory_under_domain_bus_directory_in_sysfs(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        non_existing_pci_address = "0000:00:01.0"
        with self.assertRaises(FailedPciDeviceDetection) as ex:
            get_virtio_blk_path_by_pci_address(non_existing_pci_address)

    def test_pci_does_not_exist_in_sysfs(self):
        with self.assertRaises(FailedPciDeviceDetection) as ex:
            get_virtio_blk_path_by_pci_address("0000:00:04.0")

    def test_device_does_not_exist_in_dev(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)

        with self.assertRaises(FailedPciDeviceDetection) as ex:
            get_virtio_blk_path_by_pci_address("0000:00:04.0")

    def test_get_device_by_pci_address_on_pci_bridge(self):
        path = "/sys/devices/pci0000:00/0000:00:04.0/0000:01:01.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_path_by_pci_address("0000:01:01.0")
        self.assertEqual(dev_path, "/dev/vda")
