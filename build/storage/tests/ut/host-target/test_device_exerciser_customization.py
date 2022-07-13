#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import shutil
import unittest
import tempfile
import os
import sys
import logging
import warnings

from device_exerciser_customization import (
    find_make_custom_device_exerciser,
    GetCustomizationError,
    MAKE_DEVICE_EXERCISER_FUNCTION_NAME,
)
from device_exerciser_if import DeviceExerciserIf
from host_target_grpc_server import get_device_exerciser
from device_exerciser_kvm import DeviceExerciserKvm


class FakeDeviceExerciser(DeviceExerciserIf):
    pass


def make_device_exerciser() -> DeviceExerciserIf:
    return FakeDeviceExerciser()


class DeviceExerciserCustomizationTests(unittest.TestCase):
    def setUp(self):
        logging.disable(logging.CRITICAL)
        warnings.filterwarnings("ignore", category=DeprecationWarning)
        self.tempdir = tempfile.mkdtemp()
        self.file_with_exerciser = os.path.join(
            self.tempdir, "make_device_exerciser.py"
        )
        os.symlink(__file__, self.file_with_exerciser)
        sys.path.append(self.tempdir)

    def tearDown(self):
        warnings.filterwarnings("default", category=DeprecationWarning)
        logging.disable(logging.NOTSET)
        shutil.rmtree(self.tempdir)

    def test_use_customization_if_there_is_appropriate_file(self):
        self.assertTrue(find_make_custom_device_exerciser(self.tempdir))

    def test_cannot_find_make_custom_device_exerciser_in_empty_dir(self):
        empty_dir = tempfile.mkdtemp()
        self.assertFalse(find_make_custom_device_exerciser(empty_dir))
        os.rmdir(empty_dir)

    def test_cannot_find_make_custom_device_exerciser_in_non_existing_path(self):
        with self.assertRaises(GetCustomizationError):
            self.assertFalse(find_make_custom_device_exerciser("/foobar"))

    def test_multiple_modules_creates_device_exerciser(self):
        another_file_with_exerciser = os.path.join(
            self.tempdir, "another_make_device_exerciser.py"
        )
        os.symlink(__file__, another_file_with_exerciser)
        with self.assertRaises(GetCustomizationError):
            find_make_custom_device_exerciser(self.tempdir)

    def test_uses_only_files_with_py_extensions_to_search(self):
        self.tmp_file_without_py_extension = tempfile.mktemp(dir=self.tempdir)
        with open(self.tmp_file_without_py_extension, "a") as file:
            file.write("SomeText\n")
            file.write("def " + MAKE_DEVICE_EXERCISER_FUNCTION_NAME + "():\n")
            file.write("    pass\n")

        self.assertTrue(find_make_custom_device_exerciser(self.tempdir))

    def test_other_py_modules_do_not_impact_number_of_exercisers(self):
        another_empty_py_file = os.path.join(self.tempdir, "empty_file.py")
        with open(another_empty_py_file, "a") as file:
            file.write("\n")
        self.assertTrue(find_make_custom_device_exerciser(self.tempdir))

    def test_return_none_custom_exerciser_with_none_dir(self):
        self.assertEqual(find_make_custom_device_exerciser(None), None)

    def test_return_none_custom_exerciser_with_empty_dir_name(self):
        self.assertEqual(find_make_custom_device_exerciser(""), None)


class DeviceExerciserCustomizationIsCallableTests(unittest.TestCase):
    def setUp(self):
        logging.disable(logging.CRITICAL)
        warnings.filterwarnings("ignore", category=DeprecationWarning)
        self.tempdir = tempfile.mkdtemp()
        self.file_with_not_callable_make_exerciser = os.path.join(
            self.tempdir, "file_with_not_callable_make_exerciser.py"
        )
        with open(self.file_with_not_callable_make_exerciser, "a") as file:
            file.write(f"{MAKE_DEVICE_EXERCISER_FUNCTION_NAME}='non-callable string'\n")
        sys.path.append(self.tempdir)

    def tearDown(self):
        warnings.filterwarnings("default", category=DeprecationWarning)
        logging.disable(logging.NOTSET)
        shutil.rmtree(self.tempdir)

    def test_device_exerciser_should_be_callable(self):
        with self.assertRaises(GetCustomizationError):
            find_make_custom_device_exerciser(self.tempdir)


class CustomOrDefaultDeviceExerciserCustomizationTests(
    DeviceExerciserCustomizationTests
):
    def test_get_default_device_exerciser_on_none(self):
        self.assertEqual(type(get_device_exerciser(None)), DeviceExerciserKvm)

    def test_get_default_device_exerciser_on_empty_str_dir(self):
        self.assertEqual(type(get_device_exerciser("")), DeviceExerciserKvm)

    def test_find_customized_device_exerciser(self):
        # Since module is loaded dynamically, they have different prefix names
        # For that purpose we can just compare class names rather than class
        # names with module prefixes
        self.assertEqual(
            type(get_device_exerciser(self.tempdir)).__name__,
            type(make_device_exerciser()).__name__,
        )

    def test_found_customized_device_exerciser_returns_none(self):
        with self.assertRaises(RuntimeError):
            get_device_exerciser(self.tempdir, lambda unused_path: lambda: None)

    def test_found_customized_device_exerciser_returns_obj_of_wrong_type(self):
        with self.assertRaises(RuntimeError):
            get_device_exerciser(self.tempdir, lambda unused_path: lambda: "abc")
