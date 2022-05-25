#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from multiprocessing import context
from host_target_grpc_server import HostTargetService
import host_target_pb2

import unittest
import unittest.mock


def detect_virtio_blk_device(unused):
    return "non_existing_device_name"


def successfull_fio(unused):
    return "output"


class HostTargetServerTests(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_run_fio_success(self):
        server = HostTargetService(successfull_fio, detect_virtio_blk_device)
        request = host_target_pb2.RunFioRequest()
        request.pciAddress = "unused"
        request.fioArgs = "unused"
        context = unittest.mock.MagicMock()

        reply = server.RunFio(request, context)
        context.set_code.was_not_called()
        context.set_details.was_not_called()
        self.assertTrue(reply != None)
        self.assertTrue(reply.fioOutput != None)
        self.assertTrue(reply.fioOutput != "")

    def test_run_fio_does_not_propagate_exception(self):
        def fio_throws_exception(unused):
            raise BaseException()

        server = HostTargetService(fio_throws_exception, detect_virtio_blk_device)
        request = host_target_pb2.RunFioRequest()
        request.pciAddress = "unused"
        request.fioArgs = "unused"
        context = unittest.mock.MagicMock()

        server.RunFio(request, context)
        context.set_code.assert_called()
        context.set_details.assert_called()

    def test_run_fio_does_not_propagate_exception(self):
        def detect_virtio_blk_throws_exception(unused):
            raise BaseException()

        server = HostTargetService(successfull_fio, detect_virtio_blk_throws_exception)
        request = host_target_pb2.RunFioRequest()
        request.pciAddress = "unused"
        request.fioArgs = "unused"
        context = unittest.mock.MagicMock()

        server.RunFio(request, context)
        context.set_code.assert_called()
        context.set_details.assert_called()
