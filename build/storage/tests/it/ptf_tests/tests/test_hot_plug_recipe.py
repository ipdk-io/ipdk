# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os

from ptf.base_tests import BaseTest
from system_tools.services import (
    CloneIPDKRepository,
    RunHostTargetContainer,
    RunIPUStorageContainer,
    RunStorageTargetContainer,
)
from system_tools.test_platform import HostPlatform
from test_connection import BaseTerminalMixin


class TestHostPlatform(BaseTerminalMixin, BaseTest):
    def setUp(self):
        super().setUp()
        self.storage_target_platform = HostPlatform(self.storage_target_terminal)
        self.ipu_storage_platform = HostPlatform(self.ipu_storage_terminal)
        self.host_target_platform = HostPlatform(self.host_target_terminal)

    def runTest(self):
        self.storage_target_platform.host_system_setup()
        self.ipu_storage_platform.host_system_setup()
        self.host_target_platform.host_system_setup()


class TestDeployContainers(BaseTerminalMixin, BaseTest):
    def setUp(self):
        super().setUp()
        self.storage_target_terminal.delete_all_containers()
        self.ipu_storage_terminal.delete_all_containers()
        self.host_target_terminal.delete_all_containers()

    def runTest(self):
        clone_step = CloneIPDKRepository(
            self.storage_target_terminal,
            is_teardown=False,
            repository_url="https://github.com/intelfisz/ipdk.git",
            branch="t-env",
        )
        clone_step.run()

        RunStorageTargetContainer(
            self.storage_target_terminal,
            storage_dir=os.path.join(clone_step.workdir, "ipdk/build/storage"),
        ).run()
        RunIPUStorageContainer(
            self.ipu_storage_terminal,
            storage_dir=os.path.join(clone_step.workdir, "ipdk/build/storage"),
            shared_dir=os.path.join(clone_step.workdir, "shared"),
        ).run()
        RunHostTargetContainer(
            self.host_target_terminal,
            storage_dir=os.path.join(clone_step.workdir, "ipdk/build/storage"),
        ).run()
