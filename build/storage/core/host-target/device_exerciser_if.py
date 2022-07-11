# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
class DeviceExerciserError(RuntimeError):
    pass


class DeviceExerciserIf:
    def run_fio(self, device_handle: str, fio_args: str) -> str:
        raise NotImplementedError()
