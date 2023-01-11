#!/usr/bin/env python
#
# Copyright (C) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os
import tempfile
import unittest
from helpers.file_helpers import *


class ReadWriteFileTests(unittest.TestCase):
    def setUp(self):
        self.tmp_file = tempfile.mkstemp()[1]
        self.link = "./link"

    def tearDown(self):
        if os.path.isfile(self.link):
            os.unlink(self.link)
        os.unlink(self.tmp_file)

    def test_read_raises_on_symlink(self):
        os.symlink(self.tmp_file, self.link)
        with self.assertRaises(ValueError):
            read_file_securely(self.link)

    def test_write_raises_on_symlink(self):
        os.symlink(self.tmp_file, self.link)
        with self.assertRaises(ValueError):
            write_file_securely(self.link, "test")

    def test_successful_read_write(self):
        content = "test"
        write_file_securely(self.tmp_file, content)
        self.assertEqual(read_file_securely(self.tmp_file), content)


class WriteAndRestoreFileContentTests(unittest.TestCase):
    def setUp(self):
        self.tmp_file = tempfile.mkstemp()[1]
        self.content = "test"
        self.new_content = "new content"
        write_file_securely(self.tmp_file, self.content)

    def tearDown(self):
        os.unlink(self.tmp_file)

    def test_file_content_is_temporary_changed(self):
        with WriteAndRestoreFileContent(self.tmp_file) as file:
            file.write_tmp_content(self.new_content)
            self.assertEqual(read_file_securely(self.tmp_file), self.new_content)

    def test_file_content_is_restored(self):
        with WriteAndRestoreFileContent(self.tmp_file) as file:
            file.write_tmp_content(self.new_content)
        self.assertEqual(read_file_securely(self.tmp_file), self.content)
