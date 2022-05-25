#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from pyfakefs.fake_filesystem_unittest import TestCase
from pci_devices import get_virtio_blk_path_by_pci_address
from device_exerciser import DeviceExerciser, DeviceExerciserError


class DeviceExerciserTests(TestCase):
    def setUp(self):
        self.setUpPyfakefs()

    def tearDown(self):
        pass

    def test_successful_fio_run(self):
        self.fs.create_dir("/sys/devices/pci0000:00/0000:00:04.0/virtio0/block/vda")
        self.fs.create_file("/dev/vda")
        fio_arguments = "--name=test --size=4MB"

        def fio_do_nothing(fio_args):
            fio_do_nothing.was_called = True
            self.assertTrue("vda" in fio_args)
            self.assertTrue(fio_arguments in fio_args)
            return "output"

        fio_do_nothing.was_called = False

        exerciser = DeviceExerciser(
            fio_runner=fio_do_nothing,
            virtio_blk_detector=get_virtio_blk_path_by_pci_address,
        )
        out = exerciser.run_fio("0000:00:04.0", fio_arguments)
        self.assertTrue(fio_do_nothing.was_called)
        self.assertEqual(out, "output")

    def test_any_errors_at_exercising(self):
        def raise_exception(unused):
            raise BaseException()

        exerciser = DeviceExerciser(
            fio_runner=raise_exception, virtio_blk_detector=raise_exception
        )
        with self.assertRaises(DeviceExerciserError) as ex:
            exerciser.run_fio("pcie_address", "fio_arguments")
