# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from helpers.fio_args import FioArgs
from volumes import VolumeId


class DeviceExerciserError(RuntimeError):
    pass


class DeviceExerciserIf:
    def run_fio(
        self, device_handle: str, volume_ids: set[VolumeId], fio_args: FioArgs
    ) -> str:
        raise NotImplementedError()

    def plug_device(self, device_handle: str) -> None:
        raise NotImplementedError()

    def unplug_device(self, device_handle: str) -> None:
        raise NotImplementedError()
