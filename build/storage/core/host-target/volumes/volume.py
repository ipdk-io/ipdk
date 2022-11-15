# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import uuid
import os


class VolumeId:
    def __init__(self, volume_id: str) -> None:
        self._volume_id = str(uuid.UUID(volume_id.rstrip()))

    def __str__(self) -> str:
        return self._volume_id

    def __eq__(self, __o: object) -> bool:
        if isinstance(__o, VolumeId):
            return self._volume_id == __o._volume_id
        else:
            return False

    def __hash__(self) -> int:
        return hash(self._volume_id)


class VolumeError(RuntimeError):
    pass


class Volume:
    def __init__(self, volume_path: str) -> None:
        if not os.path.exists(volume_path):
            raise VolumeError(f"Volume with path '{volume_path}' does not exist")
        self._volume_path = volume_path

    def __str__(self) -> str:
        return self._volume_path

    def __eq__(self, __o: object) -> bool:
        if isinstance(__o, Volume):
            return self._volume_path == __o._volume_path
        elif isinstance(__o, str):
            return self._volume_path == __o
        else:
            return False

    def __hash__(self) -> int:
        return hash(self._volume_path)
