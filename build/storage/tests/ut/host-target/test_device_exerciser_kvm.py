#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import os
import copy

from device_exerciser_kvm import *
from device_exerciser_if import *
from fio_args import FioArgs
from pyfakefs.fake_filesystem_unittest import patchfs


class DeviceExerciserKvmTests(unittest.TestCase):
    def setUp(self):
        virtio_blk_protocol_name = "virtio_blk"
        nvme_protocol_name = "nvme"
        self.stub_device_path = "/dev/some_device"
        self.parsed_pci_addr = ""

        def get_blk_path(pci_addr, volume_ids):
            self.parsed_pci_addr = str(pci_addr)
            return {self.stub_device_path}

        stub_get_virtio_blk_path = unittest.mock.Mock(side_effect=get_blk_path)
        stub_get_nvme_path = unittest.mock.Mock(side_effect=get_blk_path)
        self.stub_fio_output = "output"
        self.stub_run_fio = unittest.mock.Mock(return_value=self.stub_fio_output)
        self.device_exerciser = DeviceExerciserKvm(
            {
                virtio_blk_protocol_name: stub_get_virtio_blk_path,
                nvme_protocol_name: stub_get_nvme_path,
            },
            self.stub_run_fio,
        )
        self.fio_args = FioArgs('{ "some": "arg" }')

    def tearDown(self):
        self.parsed_pci_addr = ""

    def test_sma_handle_parsed_to_pci_address(self):
        self.device_exerciser.run_fio("virtio_blk:sma-0", {}, self.fio_args)
        self.assertEqual(self.parsed_pci_addr, "0000:01:00.0")

    def test_sma_handle_to_pci_on_another_bus(self):
        self.device_exerciser.run_fio("virtio_blk:sma-32", {}, self.fio_args)
        self.assertEqual(self.parsed_pci_addr, "0000:02:00.0")

    def test_sma_handle_to_pci_address_in_hex(self):
        self.device_exerciser.run_fio("virtio_blk:sma-60", {}, self.fio_args)
        self.assertEqual(self.parsed_pci_addr, "0000:02:1c.0")

    def test_irrelevant_suffix_in_sma_handle(self):
        with self.assertRaises(SmaHandleError):
            self.device_exerciser.run_fio(
                "virtio_blk:sma-0:some_irrelevant_suffix", {}, self.fio_args
            )

    def test_pass_empty_string_as_sma_handle(self):
        with self.assertRaises(SmaHandleError):
            self.device_exerciser.run_fio("", {}, self.fio_args)

    def test_pass_none_as_sma_handle(self):
        with self.assertRaises(SmaHandleError):
            self.device_exerciser.run_fio(None, {}, self.fio_args)

    def test_invalid_separator_for_protocol_in_sma_handle(self):
        with self.assertRaises(SmaHandleError):
            self.device_exerciser.run_fio("virtio_blk;sma-0", {}, self.fio_args)

    def test_physical_id_is_not_integer_in_sma_handle(self):
        with self.assertRaises(SmaHandleError):
            self.device_exerciser.run_fio("virtio_blk:sma-a", {}, self.fio_args)

    def test_invalid_separator_for_physical_id_in_sma_handle(self):
        with self.assertRaises(SmaHandleError):
            self.device_exerciser.run_fio("virtio_blk:sma_0", {}, self.fio_args)

    def test_physical_id_exceeds_number_of_buses_in_sma_handle(self):
        with self.assertRaises(SmaHandleError):
            self.device_exerciser.run_fio(
                "virtio_blk:sma-4294967295", {}, self.fio_args
            )

    def test_invalid_protocol(self):
        with self.assertRaises(DeviceExerciserError):
            self.device_exerciser.run_fio(
                "non-existing-protocol:sma-0", {}, self.fio_args
            )

    def test_successful_fio_run(self):
        out = self.device_exerciser.run_fio("virtio_blk:sma-0", {}, self.fio_args)
        self.assertEqual(out, self.stub_fio_output)
        self.assertTrue(
            self.stub_device_path in str(self.stub_run_fio.call_args.args[0])
        )

    def test_fio_args_parameter_is_not_changed(self):
        copy_fio_args = copy.deepcopy(self.fio_args)
        self.device_exerciser.run_fio("virtio_blk:sma-0", {}, self.fio_args)
        self.assertEqual(str(self.fio_args), str(copy_fio_args))

    def _create_nvme_device(self, fake_fs, pci_addr, device_num, subsysnqn):
        device_path = f"/sys/bus/pci/devices/{pci_addr}/nvme/nvme{device_num}"
        path = os.path.join(device_path, f"nvme{device_num}n1")
        fake_fs.create_dir(path)
        path = os.path.join(device_path, "subsysnqn")
        fake_fs.create_file(path, contents=subsysnqn + "\n")

    @patchfs
    def test_nvme_sma_handle_parsed_to_correct_pci_address(self, fake_fs):
        self._create_nvme_device(
            fake_fs, "0000:01:10.0", 0, "nqn.2016-06.io.spdk:vfiouser-0"
        )
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-1"
        pci_addr = "0000:01:11.0"
        self._create_nvme_device(fake_fs, pci_addr, 1, subsysnqn)

        self.device_exerciser.run_fio(f"nvme:{subsysnqn}", {}, self.fio_args)
        self.assertEqual(self.parsed_pci_addr, pci_addr)

    @patchfs
    def test_corresponding_nqn_not_found(self, fake_fs):
        self._create_nvme_device(
            fake_fs, "0000:01:10.0", 0, "nqn.2016-06.io.spdk:vfiouser-0"
        )
        subsysnqn = "nqn.2016-06.io.spdk:vfiouser-1"
        pci_addr = "0000:01:11.0"
        self._create_nvme_device(fake_fs, pci_addr, 1, subsysnqn)

        with self.assertRaises(DeviceExerciserError):
            self.device_exerciser.run_fio(
                f"nvme:{subsysnqn}-non-existing-suffix", {}, self.fio_args
            )
