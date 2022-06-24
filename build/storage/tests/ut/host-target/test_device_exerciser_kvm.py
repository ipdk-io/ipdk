#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import unittest
from pyfakefs.fake_filesystem_unittest import TestCase
from pci_devices import PciAddress
from device_exerciser_kvm import *
from device_exerciser_if import *


class KvmSmaHandleTests(TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_kvm_handle_to_protocol(self):
        handle = DeviceExerciserKvm._KvmSmaHandle("my_custom_protocol:sma-0")
        self.assertEqual(str(handle.get_protocol()), "my_custom_protocol")

    def test_kvm_handle_to_pci_address(self):
        handle = DeviceExerciserKvm._KvmSmaHandle("virtio_blk:sma-0")
        self.assertEqual(str(handle.get_pci_address()), "0000:01:00.0")

    def test_kvm_handle_to_pci_on_another_bus(self):
        handle = DeviceExerciserKvm._KvmSmaHandle("virtio_blk:sma-32")
        self.assertEqual(str(handle.get_pci_address()), "0000:02:00.0")

    def test_kvm_handle_to_pci_address_in_hex_and_upper_case(self):
        handle = DeviceExerciserKvm._KvmSmaHandle("virtio_blk:sma-60")
        self.assertEqual(str(handle.get_pci_address()), "0000:02:1C.0")

    def test_kvm_handle_some_irrelevant_suffix(self):
        with self.assertRaises(SmaHandleError):
            DeviceExerciserKvm._KvmSmaHandle("virtio_blk:sma-0:some-irrelevant-suffix")

    def test_kvm_handle_pass_empty_string(self):
        with self.assertRaises(SmaHandleError):
            DeviceExerciserKvm._KvmSmaHandle("")

    def test_kvm_handle_pass_none(self):
        with self.assertRaises(SmaHandleError):
            DeviceExerciserKvm._KvmSmaHandle(None)

    def test_invalid_separator_for_protocol(self):
        with self.assertRaises(SmaHandleError):
            DeviceExerciserKvm._KvmSmaHandle("virtio_blk;sma-0")

    def test_physical_id_is_not_integer(self):
        with self.assertRaises(SmaHandleError):
            DeviceExerciserKvm._KvmSmaHandle("virtio_blk:sma-a")

    def test_invalid_separator_for_physical_id(self):
        with self.assertRaises(SmaHandleError):
            DeviceExerciserKvm._KvmSmaHandle("virtio_blk:sma_0")

    def test_physical_id_is_exceed_number_of_buses(self):
        with self.assertRaises(SmaHandleError):
            DeviceExerciserKvm._KvmSmaHandle("virtio_blk:sma-4294967295")


class DeviceExerciserKvmTests(TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_successful_fio_run(self):
        stub_device_path = "/dev/some_device"
        stub_get_virtio_blk_path = unittest.mock.Mock(return_value=stub_device_path)
        stub_fio_output = "output"
        stub_run_fio = unittest.mock.Mock(return_value=stub_fio_output)
        device_exerciser = DeviceExerciserKvm(
            {"virtio_blk": stub_get_virtio_blk_path},
            stub_run_fio,
        )
        fio_args = "unused args"

        out = device_exerciser.run_fio("virtio_blk:sma-0", fio_args)
        self.assertEqual(out, stub_fio_output)
        self.assertTrue(stub_device_path in stub_run_fio.call_args.args[0])
        self.assertTrue(fio_args in stub_run_fio.call_args.args[0])

    def test_invalid_protocol(self):
        device_exerciser = DeviceExerciserKvm(
            {VIRTIO_BLK_PROTOCOL: unittest.mock.Mock()},
            unittest.mock.Mock(),
        )
        with self.assertRaises(DeviceExerciserError):
            device_exerciser.run_fio("non-existing-protocol:sma-0", "unused")
