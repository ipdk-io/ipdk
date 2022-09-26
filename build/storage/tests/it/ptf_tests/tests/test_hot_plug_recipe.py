# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from ptf.base_tests import BaseTest

from python_system_tools.config import (
    StorageTargetConfig, IPUStorageConfig, HostTargetConfig,
)
from python_system_tools.ssh_terminal import SSHTerminal
from python_system_tools.test_platform import HostPlatform
from python_system_tools.services import CloneRepository


class TestHostPlatform(BaseTest):

    def setUp(self):
        self.storage_target_terminal = SSHTerminal(StorageTargetConfig())
        self.ipu_storage_terminal = SSHTerminal(IPUStorageConfig())
        self.host_target_terminal = SSHTerminal(HostTargetConfig())

        self.storage_target_platform = HostPlatform(self.storage_target_terminal)
        self.ipu_storage_platform = HostPlatform(self.ipu_storage_terminal)
        self.host_target_platform = HostPlatform(self.host_target_terminal)

    def runTest(self):
        self.storage_target_platform.host_system_setup()
        self.ipu_storage_platform.host_system_setup()
        self.host_target_platform.host_system_setup()

    def tearDown(self):
        pass


class TestDeployContainers(BaseTest):

    def setUp(self):
        self.storage_target_terminal = SSHTerminal(StorageTargetConfig())
        self.ipu_storage_terminal = SSHTerminal(IPUStorageConfig())
        self.host_target_terminal = SSHTerminal(HostTargetConfig())

    def runTest(self):
        repository_step = CloneRepository(
            self.storage_target_terminal,
            is_teardown=False,
            repository_url='https://github.com/intelfisz/ipdk.git',
            branch='t-env'
        )
        repository_step.run()


    def tearDown(self):
        pass
