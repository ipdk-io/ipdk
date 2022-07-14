#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from host_target_grpc_server import HostTargetService
from device_exerciser_kvm import *
from device_exerciser_if import *

import host_target_pb2
import logging
import unittest
import unittest.mock


class HostTargetServerTests(unittest.TestCase):
    def setUp(self):
        logging.disable(logging.CRITICAL)

    def tearDown(self):
        logging.disable(logging.NOTSET)

    def test_run_fio_success(self):
        exerciser_kvm = unittest.mock.Mock()
        exerciser_kvm.run_fio = unittest.mock.Mock(return_value="output")
        server = HostTargetService(exerciser_kvm)
        request = host_target_pb2.RunFioRequest()
        request.deviceHandle = "virtio_blk:sma-0"
        request.fioArgs = "{}"
        context = unittest.mock.MagicMock()

        reply = server.RunFio(request, context)
        context.set_code.was_not_called()
        context.set_details.was_not_called()
        self.assertTrue(reply != None)
        self.assertTrue(reply.fioOutput != None)
        self.assertTrue(reply.fioOutput != "")

    def test_run_fio_does_not_propagate_exception(self):
        exerciser_kvm = unittest.mock.Mock()
        exerciser_kvm.run_fio = unittest.mock.Mock(side_effect=BaseException())
        server = HostTargetService(exerciser_kvm)
        request = host_target_pb2.RunFioRequest()
        request.deviceHandle = "virtio_blk:sma-0"
        request.fioArgs = "{}"
        context = unittest.mock.MagicMock()

        server.RunFio(request, context)
        context.set_code.assert_called()
        context.set_details.assert_called()
