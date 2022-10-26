# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import time
from typing import Callable
from helpers import read_file, write_file
from sriov_device_driver import SriovDeviceDriver


class NvmeDriver(SriovDeviceDriver):
    def __init__(
        self,
        wait_sec: int = 5,
        wait: Callable = time.sleep,
        read_file: Callable = read_file,
        write_file: Callable = write_file,
    ) -> None:
        super().__init__("nvme", wait_sec, wait, read_file, write_file)
