#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import os

from helpers.fio_args import *


class FioArgsTests(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_create_config_file(self):
        fio_args = FioArgs('{"name":"test"}')
        with fio_args.create_config_file() as config:
            self.assertTrue(config.file_name)
            self.assertTrue(os.path.isfile(config.file_name))

    def test_config_file_has_right_content(self):
        fio_args = FioArgs('{"name":"test", "size":"4MB"}')
        fio_args.add_volumes_to_exercise({"test"})
        with fio_args.create_config_file() as config:
            with open(config.file_name) as file:
                config_content = file.read()
                self.assertTrue("name=test\n" in config_content)
                self.assertTrue("size=4MB\n" in config_content)
                self.assertTrue("filename=test\n" in config_content)

    def test_config_file_is_removed_after_with(self):
        fio_args = FioArgs('{"name":"test"}')
        config_file_name = ""
        with fio_args.create_config_file() as config:
            config_file_name = config.file_name
        self.assertFalse(os.path.isfile(config_file_name))

    def test_raise_on_invalid_json_input(self):
        with self.assertRaises(FioArgsError) as ex:
            FioArgs('{"name":no-quotation-mark", "size":"4MB", "filename":"test"}')

    def test_raise_on_empty_input(self):
        with self.assertRaises(FioArgsError):
            FioArgs("")

    def test_raise_on_none_input(self):
        with self.assertRaises(FioArgsError):
            FioArgs(None)

    def test_add_argument_to_existing_args(self):
        fio_args = FioArgs('{"name":"test"}')
        fio_args.add_argument("foo", "bar")
        with fio_args.create_config_file() as config:
            with open(config.file_name) as file:
                config_content = file.read()
                self.assertTrue("name=test\n" in config_content)
                self.assertTrue("foo=bar\n" in config_content)

    def test_string_representation_in_json_form(self):
        fio_args_str = '{"name": "test"}'
        fio_args = FioArgs(fio_args_str)
        self.assertEqual(str(fio_args), fio_args_str)

    def test_no_filename_allowed(self):
        with self.assertRaises(FioArgsError) as ex:
            FioArgs('{"filename":"/dev/sda"}')

    def test_multiple_devices(self):
        fio_args = FioArgs('{"name":"test"}')
        devices = ["/dev/nvme0n1", "/dev/nvme0n3"]
        fio_args.add_volumes_to_exercise(set(devices))
        content = ""
        with fio_args.create_config_file() as config:
            with open(config.file_name) as file:
                content = file.read()

        self.assertTrue(f"[job ({devices[0]})]\nfilename={devices[0]}" in content)
        self.assertTrue(f"[job ({devices[1]})]\nfilename={devices[1]}" in content)
