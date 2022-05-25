# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import subprocess


class FioExecutionError(RuntimeError):
    pass


def run_fio(fio_args, subprocess_run=subprocess.run):
    fio_cmd = []
    try:
        fio_cmd = ["fio"] + fio_args.split()
        result = subprocess_run(fio_cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise FioExecutionError(
                "fio execution error: '"
                + str(result.stdout)
                + "' | '"
                + str(result.stderr)
                + "' "
            )
        return result.stdout
    except BaseException as ex:
        raise FioExecutionError(
            "Cannot execute cmd '" + " ".join(fio_cmd) + "' Error: " + str(ex)
        )
