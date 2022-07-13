# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import json
import tempfile
import typing


class FioArgsError(ValueError):
    pass


class FioArgs:
    class Config:
        def __init__(self, owner: "FioArgs") -> None:
            self._owner = owner
            self._file = None
            self.file_name = ""

        def __enter__(self):
            self._file = tempfile.NamedTemporaryFile()
            self.file_name = self._file.name

            with open(self.file_name, "w") as config:
                self._dump_owner_to_file(config)

            self._file.__enter__()
            return self

        def __exit__(self, exc_type, exc_val, exc_tb) -> None:
            self._file.__exit__(exc_type, exc_val, exc_tb)

        def _dump_owner_to_file(self, file: typing.TextIO) -> None:
            file.write("[job0]\n")
            for arg_key in self._owner._fio_args:
                file.write(arg_key + "=" + str(self._owner._fio_args[arg_key]) + "\n")
            file.flush()

    def __init__(self, fio_args_str: str) -> None:
        try:
            self._fio_args = json.loads(fio_args_str)
        except (json.JSONDecodeError, TypeError) as err:
            raise FioArgsError(str(err))

    def add_argument(self, key: str, value: str) -> None:
        self._fio_args[key] = value

    def create_config_file(self) -> Config:
        return FioArgs.Config(self)

    def __str__(self) -> str:
        return json.dumps(self._fio_args)
