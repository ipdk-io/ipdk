# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
def read_file(file_path: str) -> str:
    with open(file_path, "r") as f:
        return f.read()


def write_file(file_path: str, content: str) -> None:
    with open(file_path, "w") as f:
        f.write(str(content))


class WriteAndRestoreFileContent:
    def __init__(self, file_to_restore):
        self._file_to_restore = file_to_restore
        self._original_content = ""

    def __enter__(self):
        self._original_content = read_file(self._file_to_restore)
        return self

    def __exit__(self, type, value, traceback):
        write_file(self._file_to_restore, self._original_content)

    def write_tmp_content(self, content: str) -> None:
        write_file(self._file_to_restore, content)
