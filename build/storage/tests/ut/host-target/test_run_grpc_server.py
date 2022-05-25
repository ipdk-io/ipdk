#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import os
import unittest.mock
import grpc
from unittest.mock import patch
from host_target_grpc_server import run_grpc_server
from host_target_grpc_server import HostTargetService
import host_target_pb2_grpc


class RunGrpcServer(unittest.TestCase):
    def test_fail_on_invalid_address_to_listen_to(self):
        self.assertNotEqual(run_grpc_server("Invalid ip addr", 1010), 0)

    def test_fail_on_invalid_port_to_listen_to(self):
        self.assertNotEqual(run_grpc_server("0.0.0.0", "Invalid port"), 0)

    def test_success_on_keyboard_interrupt_exception(self):
        server_mock = unittest.mock.Mock()
        server_mock.add_insecure_port.side_effect = KeyboardInterrupt()

        def server_creator(unused):
            return server_mock

        self.assertEqual(run_grpc_server("Unused", "Unused", server_creator), 0)
        self.assertTrue(server_mock.add_insecure_port.was_called)

    @patch.object(host_target_pb2_grpc, "add_HostTargetServicer_to_server")
    def test_required_methods_were_called(self, add_servicer_mock):
        server_mock = unittest.mock.Mock()

        def server_creator(unused):
            return server_mock

        ip_addr = "ip_addr"
        port = "port"

        self.assertEqual(run_grpc_server(ip_addr, port, server_creator), 0)

        self.assertTrue(server_mock.add_insecure_port.was_called)
        call_args = server_mock.add_insecure_port.call_args.args
        self.assertTrue(len(call_args) == 1)
        self.assertTrue(ip_addr in call_args[0])
        self.assertTrue(port in call_args[0])
        self.assertTrue(server_mock.start.was_called)

        self.assertTrue(add_servicer_mock.was_called)
        self.assertTrue(len(add_servicer_mock.call_args.args) == 2)
        self.assertTrue(
            isinstance(add_servicer_mock.call_args.args[0], HostTargetService)
        )
        self.assertTrue(add_servicer_mock.call_args.args[1] == server_mock)
