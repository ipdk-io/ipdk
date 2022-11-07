#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from volumes import *
from pci  import PciAddress, InvalidPciAddress
from volumes import VolumeId, VolumeError
from pyfakefs.fake_filesystem_unittest import TestCase

import os
import uuid


class VirtioBlkPciDeviceTests(TestCase):
    def setUp(self):
        self.setUpPyfakefs()

    def test_get_virtio_blk_volume(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_volume(PciAddress("0000:00:04.0"))
        self.assertEqual(dev_path, {"/dev/vda"})

    def test_invalid_pci_address(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")

        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("0000:00:04.9")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("0000:00:20.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("0000:00:00:0")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("0000:00.00.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("0:00.00.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("0000:0.00.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("0000:00.0.0")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("0000:00.00.01")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress("")
        with self.assertRaises(InvalidPciAddress) as ex:
            PciAddress(None)

    def test_corner_bus_value(self):
        path = "/sys/bus/pci/devices/0000:ff:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_volume(PciAddress("0000:FF:04.0"))
        self.assertEqual(dev_path, {"/dev/vda"})

    def test_corner_device_value(self):
        path = "/sys/bus/pci/devices/0000:00:1f.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_volume(PciAddress("0000:00:1F.0"))
        self.assertEqual(dev_path, {"/dev/vda"})

    def test_corner_function_value(self):
        path = "/sys/bus/pci/devices/0000:00:04.7/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        dev_path = get_virtio_blk_volume(PciAddress("0000:00:04.7"))
        self.assertEqual(dev_path, {"/dev/vda"})

    def test_multiple_domains(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/bus/pci/devices/0001:00:04.0/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")

        dev_path = get_virtio_blk_volume(PciAddress("0001:00:04.0"))
        self.assertEqual(dev_path, {"/dev/vdb"})

    def test_multiple_buses(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/bus/pci/devices/0000:01:04.0/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")

        dev_path = get_virtio_blk_volume(PciAddress("0000:01:04.0"))
        self.assertEqual(dev_path, {"/dev/vdb"})

    def test_multiple_devices(self):
        path = "/sys/bus/pci/devices/0000:00:00.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/bus/pci/devices/0000:00:01.0/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")

        dev_path = get_virtio_blk_volume(PciAddress("0000:00:01.0"))
        self.assertEqual(dev_path, {"/dev/vdb"})

    def test_multiple_functions(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/bus/pci/devices/0000:00:04.1/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")

        dev_path = get_virtio_blk_volume(PciAddress("0000:00:04.1"))
        self.assertEqual(dev_path, {"/dev/vdb"})

    def test_no_block_device_exists(self):
        path_to_device = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block"
        self.fs.create_dir(path_to_device)
        with self.assertRaises(FailedVolumeDetection) as ex:
            get_virtio_blk_volume(PciAddress("0000:00:00.0"))

    def test_multiple_block_devices_in_virtio_dir(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")
        with self.assertRaises(FailedVolumeDetection) as ex:
            get_virtio_blk_volume(PciAddress("0000:00:04.0"))

    def test_no_block_devices(self):
        path = "/sys/bus/pci/devices/0000:00:04.0"
        self.fs.create_dir(path)
        with self.assertRaises(FailedVolumeDetection) as ex:
            get_virtio_blk_volume(PciAddress("0000:00:04.0"))

    def test_no_device_in_virtio_block(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block"
        self.fs.create_dir(path)
        with self.assertRaises(FailedVolumeDetection) as ex:
            get_virtio_blk_volume(PciAddress("0000:00:04.0"))

    def test_multiple_block_devices_under_different_virtio_dirs(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio1/block/vdb"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vdb")
        with self.assertRaises(FailedVolumeDetection) as ex:
            get_virtio_blk_volume(PciAddress("0000:00:04.0"))

    def test_no_directory_under_domain_bus_directory_in_sysfs(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")
        non_existing_pci_address = PciAddress("0000:00:01.0")
        with self.assertRaises(FailedVolumeDetection) as ex:
            get_virtio_blk_volume(non_existing_pci_address)

    def test_pci_does_not_exist_in_sysfs(self):
        with self.assertRaises(FailedVolumeDetection) as ex:
            get_virtio_blk_volume(PciAddress("0000:00:04.0"))

    def test_device_does_not_exist_in_dev(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)

        with self.assertRaises(VolumeError) as ex:
            get_virtio_blk_volume(PciAddress("0000:00:04.0"))

    def test_volume_id_is_not_allowed_for_virtio_blk(self):
        path = "/sys/bus/pci/devices/0000:00:04.0/virtio0/block/vda"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/vda")

        with self.assertRaises(FailedVolumeDetection) as ex:
            get_virtio_blk_volume(
                PciAddress("0000:00:04.0"),
                {VolumeId(str(uuid.uuid1()))},
            )


class NvmePciDeviceTests(TestCase):
    def setUp(self):
        self.setUpPyfakefs()

    def test_get_device_by_pci_address(self):
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n1"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0n1")
        dev_paths = get_nvme_volumes(PciAddress("0000:01:00.0"))
        self.assertEqual(dev_paths, {"/dev/nvme0n1"})

    def test_no_namespace_on_device(self):
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0")
        dev_paths = get_nvme_volumes(PciAddress("0000:01:00.0"))
        self.assertEqual(dev_paths, set())

    def test_multiple_namespaces_on_device(self):
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n1"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0n1")
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n2"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0n2")
        dev_paths = get_nvme_volumes(PciAddress("0000:01:00.0"))
        self.assertEqual(dev_paths, {"/dev/nvme0n1", "/dev/nvme0n2"})

    def test_more_than_ten_namespaces(self):
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n11"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0n11")
        dev_paths = get_nvme_volumes(PciAddress("0000:01:00.0"))
        self.assertEqual(dev_paths, {"/dev/nvme0n11"})

    def test_namespace_internal_files_handled_correctly(self):
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n1/another_file"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0n1")
        dev_paths = get_nvme_volumes(PciAddress("0000:01:00.0"))
        self.assertEqual(dev_paths, {"/dev/nvme0n1"})

    def test_namespace_with_controller_part_in_the_end(self):
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n1c1"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0n1")

        dev_paths = get_nvme_volumes(PciAddress("0000:01:00.0"))
        self.assertEqual(dev_paths, {"/dev/nvme0n1"})

    def test_namespace_with_controller_part_in_the_middle(self):
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0c1n1"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0n1")

        dev_paths = get_nvme_volumes(PciAddress("0000:01:00.0"))
        self.assertEqual(dev_paths, {"/dev/nvme0n1"})

    def test_namespace_does_not_exist_under_dev(self):
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n1"
        self.fs.create_dir(path)
        self.fs.create_file("/dev/nvme0n1")

        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n2"
        self.fs.create_dir(path)

        with self.assertRaises(VolumeError) as ex:
            get_nvme_volumes(PciAddress("0000:01:00.0"))

    def test_get_nvme_volumes(self):
        disk_uuid = uuid.uuid1()
        volume_ids = [VolumeId(str(disk_uuid))]
        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n1"
        self.fs.create_dir(path)
        self.fs.create_file(
            os.path.join(path, "uuid"), contents=str(uuid.uuid1()) + "\n"
        )
        self.fs.create_file("/dev/nvme0n1")

        path = "/sys/bus/pci/devices/0000:01:00.0/nvme/nvme0/nvme0n2"
        self.fs.create_dir(path)
        self.fs.create_file(os.path.join(path, "uuid"), contents=str(disk_uuid))
        self.fs.create_file("/dev/nvme0n2")

        dev_paths = get_nvme_volumes(PciAddress("0000:01:00.0"), volume_ids)
        self.assertEqual(dev_paths, {"/dev/nvme0n2"})
