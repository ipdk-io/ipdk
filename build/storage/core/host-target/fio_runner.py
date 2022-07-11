# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import subprocess


class FioExecutionError(RuntimeError):
    pass


def run_fio(fio_args: str) -> str:
    fio_cmd = []
    try:
        fio_cmd = ["fio"] + fio_args.split()
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
