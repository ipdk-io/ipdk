#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
from multiprocessing.sharedctypes import Value
from hot_plug_provider import ActionExecutionError, HotPlugProvider
from pathlib import Path
import socket
import os
from unittest.mock import patch
import unittest


class SocketTestEnvironment(unittest.TestCase):
    def setUp(self):
        self.fake_socket_name = "fake_socket"
        self.fake_socket_path = "/tmp/" + self.fake_socket_name
        self.fake_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.fake_socket.bind(self.fake_socket_path)

    def tearDown(self):
        self.fake_socket.close()
        os.remove(self.fake_socket_path)


class HotPlugValidationBaseTestCases:
    @patch("hot_plug_provider.subprocess.call")
    class Tests(SocketTestEnvironment):
        def setUp(self):
            SocketTestEnvironment.setUp(self)
            self.shared_dir_path = "/tmp"
            self.host_shared_dir_path = "/home/user/ipdk-shared_dir"
            self.non_existing_path = "/tmp/non-existing_path"

            self.provider = HotPlugProvider(
                self.shared_dir_path, self.host_shared_dir_path
            )
            self.disk_operation = None

        def tearDown(self):
            SocketTestEnvironment.tearDown(self)

        def test_pass_none_shared_dir(self, unused):
            with self.assertRaises(ValueError) as ex:
                HotPlugProvider(None, self.host_shared_dir_path)

        def test_pass_none_host_shared_dir(self, unused):
            with self.assertRaises(ValueError) as ex:
                HotPlugProvider(self.shared_dir_path, None)

        def test_non_existing_path_to_vm_monitor(self, mock_subprocess_call):
            with self.assertRaises(FileNotFoundError) as ex:
                self.disk_operation(
                    vm_monitor=self.non_existing_path,
                    vhost_virtio_blk=self.fake_socket_path,
                )
            mock_subprocess_call.assert_not_called()

        def test_non_existing_path_to_vhost(self, mock_subprocess_call):
            with self.assertRaises(FileNotFoundError) as ex:
                self.disk_operation(
                    vm_monitor=self.fake_socket_path,
                    vhost_virtio_blk=self.non_existing_path,
                )
            mock_subprocess_call.assert_not_called()

        def test_pass_valid_sockets(self, mock_subprocess_call):
            mock_subprocess_call.return_value = 0
            was_exception_raised = False
            try:
                self.disk_operation(self.fake_socket_path, self.fake_socket_path)
            except:
                was_exception_raised = True

            self.assertEqual(was_exception_raised, False)
            mock_subprocess_call.assert_called_once()

        def test_hot_plug_call_failed(self, mock_subprocess_call):
            mock_subprocess_call.return_value = 1

            with self.assertRaises(ActionExecutionError) as ex:
                self.disk_operation(self.fake_socket_path, self.fake_socket_path)

        def test_hot_plug_generates_correct_device_id(self, mock_subprocess_call):
            mock_subprocess_call.return_value = 0

            vm = self.fake_socket_name
            vhost0 = " " + self.fake_socket_name + "  "
            vhost1 = vhost0.strip()

            self.disk_operation(vm, vhost0)
            self.disk_operation(vm, vhost1)
            call_args = mock_subprocess_call.call_args_list
            self.assertTrue(len(call_args) == 2)
            self.assertTrue(call_args[0] == call_args[1])

        def test_pass_none_vm(self, unused):
            with self.assertRaises(ValueError) as ex:
                self.disk_operation(None, self.fake_socket_path)

        def test_pass_none_vhost(self, unused):
            with self.assertRaises(ValueError) as ex:
                self.disk_operation(self.fake_socket_path, None)


class HotPlugValidation(HotPlugValidationBaseTestCases.Tests):
    def setUp(self):
        HotPlugValidationBaseTestCases.Tests.setUp(self)
        self.disk_operation = self.provider.hot_plug_vhost_virtio_blk

    def tearDown(self):
        HotPlugValidationBaseTestCases.Tests.tearDown(self)

    @patch("hot_plug_provider.subprocess.call")
    @patch.object(HotPlugProvider, "_generate_device_id")
    def test_hot_plug_call_args(self, mock_device_id_generator, mock_subprocess_call):
        device_id = "42"
        mock_subprocess_call.return_value = 0
        mock_device_id_generator.return_value = device_id

        vm = self.fake_socket_name
        vhost = self.fake_socket_name

        self.disk_operation(vm, vhost)
        mock_subprocess_call.assert_called_once_with(
            "/hot-plug.sh "
            + os.path.join(self.shared_dir_path, vm)
            + " "
            + os.path.join(self.host_shared_dir_path, vhost)
            + " "
            + device_id,
            shell=True,
        )

    @patch("hot_plug_provider.subprocess.call")
    @patch.object(HotPlugProvider, "_generate_device_id")
    def test_hot_plug_call_args_with_trailing_whitespaces(
        self, mock_device_id_generator, mock_subprocess_call
    ):
        device_id = "42"
        mock_subprocess_call.return_value = 0
        mock_device_id_generator.return_value = device_id

        vm = "  " + self.fake_socket_name + "   "
        vhost = "  " + self.fake_socket_name + "  "

        self.disk_operation(vm, vhost)

        mock_subprocess_call.assert_called_once_with(
            "/hot-plug.sh "
            + os.path.join(self.shared_dir_path, self.fake_socket_name)
            + " "
            + os.path.join(self.host_shared_dir_path, self.fake_socket_name)
            + " "
            + device_id,
            shell=True,
        )


class HotUnplugValidation(HotPlugValidationBaseTestCases.Tests):
    def setUp(self):
        HotPlugValidationBaseTestCases.Tests.setUp(self)
        self.disk_operation = self.provider.hot_unplug_vhost_virtio_blk

    def tearDown(self):
        HotPlugValidationBaseTestCases.Tests.tearDown(self)

    @patch("hot_plug_provider.subprocess.call")
    @patch.object(HotPlugProvider, "_generate_device_id")
    def test_hot_plug_call_args(self, mock_device_id_generator, mock_subprocess_call):
        device_id = "42"
        mock_subprocess_call.return_value = 0
        mock_device_id_generator.return_value = device_id

        vm = self.fake_socket_name
        vhost = self.fake_socket_name

        self.disk_operation(vm, vhost)
        mock_subprocess_call.assert_called_once_with(
            "/hot-unplug.sh "
            + os.path.join(self.shared_dir_path, vm)
            + " "
            + device_id,
            shell=True,
        )

    @patch("hot_plug_provider.subprocess.call")
    @patch.object(HotPlugProvider, "_generate_device_id")
    def test_hot_plug_call_args_with_trailing_whitespaces(
        self, mock_device_id_generator, mock_subprocess_call
    ):
        device_id = "42"
        mock_subprocess_call.return_value = 0
        mock_device_id_generator.return_value = device_id

        vm = "  " + self.fake_socket_name + "   "
        vhost = "  " + self.fake_socket_name + "  "

        self.disk_operation(vm, vhost)

        mock_subprocess_call.assert_called_once_with(
            "/hot-unplug.sh "
            + os.path.join(self.shared_dir_path, self.fake_socket_name)
            + " "
            + device_id,
            shell=True,
        )
