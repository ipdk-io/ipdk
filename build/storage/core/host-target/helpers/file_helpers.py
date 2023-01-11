# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import os


def read_file(file_path: str) -> str:
    with open(file_path, "r") as f:
        return f.read()


def write_file(file_path: str, content: str) -> None:
    with open(file_path, "w") as f:
        f.write(str(content))


def check_path(file_path: str) -> None:
    if os.path.islink(file_path):
        raise ValueError("Cannot operate on symlinks due to security implications")


def read_file_securely(file_path: str) -> str:
    check_path(file_path)
    return read_file(file_path)


def write_file_securely(file_path: str, content: str) -> None:
    check_path(file_path)

    return write_file(file_path, content)


class WriteAndRestoreFileContent:
    def __init__(
        self,
        file_to_restore,
        write_file=write_file_securely,
        read_file=read_file_securely,
    ):
        self._file_to_restore = file_to_restore
        self._original_content = ""
        self._write_file = write_file
        self._read_file = read_file

    def __enter__(self):
        self._original_content = self._read_file(self._file_to_restore)
        return self

    def __exit__(self, type, value, traceback):
        self._write_file(self._file_to_restore, self._original_content)

    def write_tmp_content(self, content: str) -> None:
        self._write_file(self._file_to_restore, content)
