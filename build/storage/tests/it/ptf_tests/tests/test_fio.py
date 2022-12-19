# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from ptf.base_tests import BaseTest
from system_tools.config import TestConfig
from system_tools.test_platform import PlatformFactory


class Fio(BaseTest):
    def setUp(self):
        self.tests_config = TestConfig()
        self.platforms_factory = PlatformFactory(self.tests_config.cmd_sender_platform)
        self.storage_target_platform = (
            self.platforms_factory.create_storage_target_platform()
        )
        self.ipu_storage_platform = self.platforms_factory.create_ipu_storage_platform()
        self.host_target_platform = self.platforms_factory.create_host_target_platform()

    def runTest(self):
        self.assertTrue(
            self.storage_target_platform.is_port_free(self.tests_config.nvme_port)
        )
        self.storage_target_platform.create_subsystem(
            self.tests_config.nqn,
            self.tests_config.nvme_port,
            self.tests_config.spdk_port,
        )
        self.assertFalse(
            self.storage_target_platform.is_port_free(self.tests_config.nvme_port)
        )
        self.assertTrue(
            self.storage_target_platform.is_app_listening_on_port(
                "spdk_tgt", self.tests_config.nvme_port
            )
        )

        remote_nvme_storages = self.storage_target_platform.create_ramdrives(
            self.tests_config.min_ramdrive,
            self.tests_config.nvme_port,
            self.tests_config.nqn,
            self.tests_config.spdk_port,
        )

        self.assertEqual(len(remote_nvme_storages), self.tests_config.min_ramdrive)

        self.assertEqual(
            self.host_target_platform.get_number_of_virtio_blk_devices(), 0
        )
        devices_handles = (
            self.ipu_storage_platform.create_virtio_blk_devices_sequentially(
                self.host_target_platform.get_service_address(),
                remote_nvme_storages,
            )
        )

        fio_modes = ['randrw', 'randread', 'write', 'readwrite', 'randwrite', 'read', 'trim']

        x = devices_handles[0]
        for mode in fio_modes:
            fio_with_params = x.run_fio_with_params(mode=mode, runtime=1, numjobs=1, time_based=1, group_reporting=1)
            print(fio_with_params)
            self.assertIn("min=", fio_with_params)
        # for device in devices_handles:
        #     fio = device.run_fio()
        #     fio_with_params = device.run_fio_with_params(mode="randrw", runtime=1, numjobs=1, time_based=1,
        #                                                  group_reporting=1)
        #     print(fio)
        #     print("now with params")
        #     print(fio_with_params)
            # self.assertIn("err= 0", fio)

            self.assertIn("err= 0", fio_with_params)

    def tearDown(self):
        self.ipu_storage_platform.clean()
        self.storage_target_platform.clean()
        self.host_target_platform.clean()
