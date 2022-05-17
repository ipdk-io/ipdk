# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import fio_runner
import pci_devices
import os


class DeviceExerciserError(RuntimeError):
    pass


class DeviceExerciser:
    def __init__(self, fio_runner=fio_runner.run_fio,
                 virtio_blk_detector=pci_devices.get_virtio_blk_path_by_pci_address):
        self.fio_runner = fio_runner
        self.virtio_blk_detector = virtio_blk_detector

    def run_fio(self, pci_address, fio_args):
        try:
            device_path = self.virtio_blk_detector(pci_address)
            fio_args_with_device = fio_args + " --filename=" + device_path
            return self.fio_runner(fio_args_with_device)
        except BaseException as ex:
            raise DeviceExerciserError(str(ex))
