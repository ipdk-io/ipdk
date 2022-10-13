# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os

from ptf.base_tests import BaseTest
from system_tools.const import STORAGE_DIR_PATH
from tests.steps.initial_steps import (
    CloneIPDKRepository,
    RunHostTargetContainer,
    RunIPUStorageContainer,
    RunStorageTargetContainer,
)
from system_tools.test_platform import HostTargetPlatform, IPUStoragePlatform, StorageTargetPlatform
from test_connection import BaseTerminalMixin


class TestTestPlatforms(BaseTerminalMixin, BaseTest):
    def setUp(self):
        super().setUp()
        self.storage_target_platform = StorageTargetPlatform()
        self.ipu_storage_platform = IPUStoragePlatform()
        self.host_target_platform = HostTargetPlatform()

    def runTest(self):
        self.storage_target_platform.set_system_setup()
        self.ipu_storage_platform.set_system_setup()
        self.host_target_platform.set_system_setup()

        self.storage_target_platform.check_system_setup()
        self.ipu_storage_platform.check_system_setup()
        self.host_target_platform.check_system_setup()


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
        )
        clone_step.run()

        RunStorageTargetContainer(
            self.storage_target_terminal,
            storage_dir=os.path.join(clone_step.workdir, STORAGE_DIR_PATH),
        ).run()
        RunIPUStorageContainer(
            self.ipu_storage_terminal,
            storage_dir=os.path.join(clone_step.workdir, STORAGE_DIR_PATH),
            shared_dir=os.path.join(clone_step.workdir, "shared"),
        ).run()
        RunHostTargetContainer(
            self.host_target_terminal,
            storage_dir=os.path.join(clone_step.workdir, STORAGE_DIR_PATH),
        ).run()
