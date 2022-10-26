# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import time
from typing import Callable
from device_driver import DeviceDriver
from helpers import read_file, write_file


class VirtioPciDriver(DeviceDriver):
    def __init__(
        self,
        wait_sec: int = 5,
        wait: Callable = time.sleep,
        read_file: Callable = read_file,
        write_file: Callable = write_file,
    ) -> None:
        super().__init__("virtio-pci", wait_sec, wait, read_file, write_file)
