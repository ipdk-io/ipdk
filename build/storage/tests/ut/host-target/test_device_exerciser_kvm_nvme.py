#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os
import test_device_exerciser_kvm

from device_exerciser_kvm import *
from device_exerciser_if import *
from fake_pci_sys_fs import FakePciSysFs


class DeviceExerciserNvmeTest(test_device_exerciser_kvm.DeviceExerciserTest):
    def setUp(self):
        super().setUp()
        self.nvme_protocol_name = NVME_PROTOCOL
        self.max_number_of_vfs = 4
        self.sys_fs = FakePciSysFs(self.fs, self.nvme_protocol_name)
