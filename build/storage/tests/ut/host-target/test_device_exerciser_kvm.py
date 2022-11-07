#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import unittest


from device_exerciser_kvm import *
from device_exerciser_if import *
from helpers.fio_args import FioArgs
from pyfakefs.fake_filesystem_unittest import TestCase


class DeviceExerciserTest(TestCase):
    def setUp(self):
        self.setUpPyfakefs()
        self.stub_device_path = "/dev/some_device"
        self.parsed_pci_addr = ""

        def get_blk_path(pci_addr, _):
            self.parsed_pci_addr = str(pci_addr)
            return {self.stub_device_path}

        self.stub_get_virtio_blk_path = unittest.mock.Mock(side_effect=get_blk_path)
        self.stub_get_nvme_path = unittest.mock.Mock(side_effect=get_blk_path)
        self.stub_fio_output = "output"
        self.stub_run_fio = unittest.mock.Mock(return_value=self.stub_fio_output)
        self.fio_args = FioArgs('{ "some": "arg" }')

    def tearDown(self):
        self.parsed_pci_addr = ""
