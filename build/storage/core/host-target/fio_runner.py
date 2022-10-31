# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import subprocess
from helpers.fio_args import FioArgs


class FioExecutionError(RuntimeError):
    pass


def run_fio(fio_args: FioArgs):
    fio_cmd = []
    try:
        with fio_args.create_config_file() as config:
            fio_cmd = ["fio", config.file_name]
            result = subprocess.run(fio_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                raise FioExecutionError(
                    "fio execution error: '"
                    + str(result.stdout)
                    + "' | '"
                    + str(result.stderr)
                    + "' "
                )
            return result.stdout
    except AttributeError as ex:
        raise FioExecutionError("Invalid input argument '" + str(fio_args) + "'")
