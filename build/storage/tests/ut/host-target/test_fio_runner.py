#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import os

from fio_runner import run_fio
from fio_runner import FioExecutionError


class FioRunner(unittest.TestCase):
    def setUp(self):
        self.fio_file = "test"
        self.fio_args = "--name=test --size=4MB --filename=test"

    def tearDown(self):
        if os.path.exists(self.fio_file):
            os.remove(self.fio_file)

    def test_successful_fio_run(self):
        try:
            run_fio(self.fio_args)
        except FioExecutionError as ex:
            self.fail(str(ex))

        self.assertTrue(os.path.exists(self.fio_file))

    def test_successful_fio_run_output(self):
        out = run_fio(self.fio_args)
        self.assertTrue(out.find("READ: bw=") != -1)

    def test_invalid_fio_arg(self):
        with self.assertRaises(FioExecutionError) as ex:
            run_fio("some-non-existing-arg")

    def test_pass_invalid_arg_type(self):
        with self.assertRaises(FioExecutionError) as ex:
            run_fio(123)

    def test_no_concat_cmds_allowed(self):
        with self.assertRaises(FioExecutionError) as ex:
            run_fio("ls -l && ls")
        with self.assertRaises(FioExecutionError) as ex:
            run_fio("ls -l || ls")
        with self.assertRaises(FioExecutionError) as ex:
            run_fio("ls -l ; ls")
