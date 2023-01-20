#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os
import copy

import test_device_exerciser_kvm


from device_exerciser_kvm import *
from device_exerciser_if import *
from helpers.fio_args import FioArgs
from helpers.file_helpers import *
from fake_pci_sys_fs import FakePciSysFs


class DeviceExerciserVirtioBlkTest(test_device_exerciser_kvm.DeviceExerciserTest):
    def setUp(self):
        super().setUp()
        self.virtio_blk_protocol_name = VIRTIO_BLK_PROTOCOL
        self.sys_fs = FakePciSysFs(self.fs, "virtio-pci")
        self.device_exerciser = self._create_test_device_exerciser()

    def _create_test_device_exerciser(self, wait=lambda x: None):
        return DeviceExerciserKvm(
            {
                self.virtio_blk_protocol_name: self.stub_get_virtio_blk_path,
            },
            self.stub_run_fio,
            wait,
            self.sys_fs.get_read_file_wrapper(),
            self.sys_fs.get_write_file_wrapper(),
        )

    def _create_plugged_virtio_blk_device(self, pci_addr):
        pci_device_dir = f"/sys/bus/pci/devices/{pci_addr}"
        self.fs.create_symlink(
            os.path.join(self.driver_path, str(pci_addr)), pci_device_dir
        )

    def _create_pci_virtio_blk_device(self, pci_addr):
        pci_device_dir = f"/sys/bus/pci/devices/{pci_addr}"
        self.fs.create_file(os.path.join(pci_device_dir, "driver_override"))

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

    def test_successfully_plugged_virtio_blk_device(self):
        sma_handle = "virtio_blk:sma-0"
        pci_addr = "0000:01:00.0"
        self.sys_fs.create_pci_device(pci_addr)
        self.device_exerciser.plug_device(sma_handle)
        self.assertEqual(read_file(self.sys_fs.get_bind_path()), pci_addr)
        self.assertEqual(read_file(self.sys_fs.get_enable_path(pci_addr)), "1")

    def test_do_not_bind_virtio_blk_if_is_already_plugged(self):
        sma_handle = "virtio_blk:sma-0"
        pci_addr = "0000:01:00.0"
        self.sys_fs.create_pci_device(pci_addr)
        self.sys_fs.bind_pci_device_to_driver(pci_addr)
        self.device_exerciser.plug_device(sma_handle)
        self.assertEqual(read_file(self.sys_fs.get_bind_path()), "")

    def test_device_do_not_appear_in_sys_fs(self):
        sma_handle = "virtio_blk:sma-0"
        device_exerciser = self._create_test_device_exerciser()

        with self.assertRaises(DeviceExerciserError):
            device_exerciser.plug_device(sma_handle)

    def test_successfully_plugged_virtio_blk_with_multiple_tries(self):
        sma_handle = "virtio_blk:sma-0"
        pci_addr = "0000:01:00.0"
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
        self.assertTrue(stub_wait.counter > 0)

    def test_virtio_blk_appears_in_sys_fs_with_multiple_tries(self):
        sma_handle = "virtio_blk:sma-0"
        pci_addr = "0000:01:00.0"

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

    def test_unsuccessfully_plugged_virtio_blk_device(self):
        sma_handle = "virtio_blk:sma-0"
        self.sys_fs.create_pci_device("0000:01:00.0")
        self.sys_fs.do_not_bind_device_to_driver()
        with self.assertRaises(DeviceExerciserError):
            self.device_exerciser.plug_device(sma_handle)

    def test_virtio_blk_is_not_unbound_at_unplug(self):
        sma_handle = "virtio_blk:sma-0"
        pci_addr = "0000:01:00.0"
        self.sys_fs.create_pci_device(pci_addr)
        self.sys_fs.bind_pci_device_to_driver(pci_addr)
        self.sys_fs.do_not_unbind_device_from_driver()
        with self.assertRaises(DeviceExerciserError):
            self.device_exerciser.unplug_device(sma_handle)

    def test_successfully_unplugged_virtio_blk(self):
        sma_handle = "virtio_blk:sma-0"
        pci_addr = "0000:01:00.0"
        self.sys_fs.create_pci_device(pci_addr)
        self.sys_fs.bind_pci_device_to_driver(pci_addr)
        self.device_exerciser.unplug_device(sma_handle)
        self.assertEqual(read_file(self.sys_fs.get_unbind_path()), pci_addr)
