#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import tempfile
import shutil
import os

from device_exerciser_customization import find_make_custom_device_exerciser


class DeviceExerciserCustomizationItTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tempdir)

    def _create_make_device_exerciser_file(self, path):
        with open(path, "a") as file:
            file.write("import sys\n")
            file.write("import os\n")
            file.write("SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))\n")
            file.write("sys.path.append(SCRIPT_DIR)\n")
            file.write("import target.custom_device_exerciser\n")
            file.write("def make_device_exerciser():\n")
            file.write("    return target.custom_device_exerciser.Exerciser()\n")

    def _create_device_exerciser_file(self, path):
        with open(path, "a") as file:
            file.write("import device_exerciser_if\n")
            file.write("class Exerciser(device_exerciser_if.DeviceExerciserIf):\n")
            file.write("    def run_fio(self, device_handle, fio_args):\n")
            file.write("        return 'ok'\n")

    def test_deployment_of_customized_device_exerciser(self):
        os.mkdir(os.path.join(self.tempdir, "target"))
        make_device_exerciser_file = os.path.join(
            self.tempdir, "make_custom_device_exerciser.py"
        )
        self._create_make_device_exerciser_file(make_device_exerciser_file)
        device_exerciser_file = os.path.join(
            self.tempdir, "target/custom_device_exerciser.py"
        )
        self._create_device_exerciser_file(device_exerciser_file)

        make_device_exerciser = find_make_custom_device_exerciser(self.tempdir)
        self.assertTrue(make_device_exerciser)
        self.assertTrue(make_device_exerciser())
        self.assertEqual(
            str(type(make_device_exerciser())),
            "<class 'target.custom_device_exerciser.Exerciser'>",
        )
