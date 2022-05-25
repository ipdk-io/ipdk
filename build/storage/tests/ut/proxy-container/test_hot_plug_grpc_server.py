#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import hot_plug_pb2
from hot_plug_provider import HotPlugProvider
from hot_plug_grpc_server import HotPlugService, InvalidHotPlugProvider
import grpc
import unittest
from unittest.mock import patch


class HotPlugServerTests(unittest.TestCase):
    def setUp(self):
        self.server = HotPlugService(HotPlugProvider("stub", "stub"))
        self.context = unittest.mock.MagicMock()

    def tearDown(self):
        pass

    def _test_server_does_not_propagate_exception(
        self, stub_provider_operation, server_operation
    ):
        err_description = "exception description"
        stub_provider_operation.side_effect = BaseException(err_description)
        request = hot_plug_pb2.HotPlugRequest()

        reply = server_operation(request, self.context)
        self.context.set_code.assert_called()
        self.context.set_details.assert_called()
        self.assertTrue(reply != None)

    @patch.object(HotPlugProvider, "hot_plug_vhost_virtio_blk")
    def test_hot_plug_does_not_propagate_exception(self, mock_provider):
        self._test_server_does_not_propagate_exception(
            mock_provider, self.server.HotPlugVirtioBlk
        )

    @patch.object(HotPlugProvider, "hot_unplug_vhost_virtio_blk")
    def test_hot_unplug_does_not_propagate_exception(self, mock_provider):
        self._test_server_does_not_propagate_exception(
            mock_provider, self.server.HotUnplugVirtioBlk
        )

    def _test_server_operation_success(self, stub_provider_operation, server_operation):
        vm = "vm"
        vhost = "vhost"
        request = hot_plug_pb2.HotPlugRequest()
        request.vmId = vm
        request.vhostVirtioBlkId = vhost

        reply = server_operation(request, self.context)

        stub_provider_operation.assert_called_with(vm, vhost)

        self.context.set_code.was_not_called()
        self.context.set_details.was_not_called()
        self.assertTrue(reply != None)

    @patch.object(HotPlugProvider, "hot_plug_vhost_virtio_blk")
    def test_hot_plug_success(self, mock_provider):
        self._test_server_operation_success(mock_provider, self.server.HotPlugVirtioBlk)

    @patch.object(HotPlugProvider, "hot_unplug_vhost_virtio_blk")
    def test_hot_unplug_success(self, mock_provider):
        self._test_server_operation_success(
            mock_provider, self.server.HotUnplugVirtioBlk
        )
