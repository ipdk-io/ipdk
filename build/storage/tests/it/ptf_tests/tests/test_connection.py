# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from ptf.base_tests import BaseTest

from python_system_tools.config import (
    StorageTargetConfig, IPUStorageConfig, HostTargetConfig,
)
from python_system_tools.ssh_terminal import SSHTerminal


class TestTerminalConnect(BaseTest):

    def setUp(self):
        self.storage_target_terminal = SSHTerminal(StorageTargetConfig())
        self.ipu_storage_terminal = SSHTerminal(IPUStorageConfig())
        self.host_target_terminal = SSHTerminal(HostTargetConfig())

    def runTest(self):
        self.assertEqual(
            self.storage_target_terminal.execute("whoami")[0],
            self.storage_target_terminal.config.username,
        )
        self.assertEqual(
            self.ipu_storage_terminal.execute("whoami")[0],
            self.ipu_storage255.config.username,
        )
        self.assertEqual(
            self.host_target_terminal.execute("whoami")[0],
            self.host_target_terminal.config.username,
        )

    def tearDown(self):
        pass


class TestTerminalConnectHasRootPrivilegnes(BaseTest):

    def setUp(self):
        self.storage_target_terminal = SSHTerminal(StorageTargetConfig())
        self.ipu_storage_terminal = SSHTerminal(IPUStorageConfig())
        self.host_target_terminal = SSHTerminal(HostTargetConfig())

    def runTest(self):
        self.assertEqual(
            self.storage_target_terminal.execute("sudo whoami")[0],
            "root",
        )
        self.assertEqual(
            self.ipu_storage_terminal.execute("sudo whoami")[0],
            "root",
        )
        self.assertEqual(
            self.host_target_terminal.execute("sudo whoami")[0],
            "root",
        )

    def tearDown(self):
        pass
