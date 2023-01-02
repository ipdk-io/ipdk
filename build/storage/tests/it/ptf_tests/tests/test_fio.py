# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
from system_tools.const import FIO_WRITE, FIO_RANDREAD, FIO_READWRITE, FIO_RANDRW, FIO_READ, FIO_TRIM, FIO_RANDWRITE
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
        self.storage_target_platform.create_subsystem(
            self.tests_config.nqn,
            self.tests_config.nvme_port,
            self.tests_config.spdk_port,
        )

        remote_nvme_storages = self.storage_target_platform.create_ramdrives(
            self.tests_config.min_ramdrive,
            self.tests_config.nvme_port,
            self.tests_config.nqn,
            self.tests_config.spdk_port,
        )

        devices_handles = (
            self.ipu_storage_platform.create_virtio_blk_devices_sequentially(
                self.host_target_platform.get_service_address(),
                remote_nvme_storages,
            )
        )

        for device in devices_handles:
            fio_randrw = device.run_fio_dictionary(FIO_RANDRW)
            print(fio_randrw)
            self.assertIn("err= 0", fio_randrw)
            fio_randread = device.run_fio_dictionary(FIO_RANDREAD)
            print(fio_randread)
            self.assertIn("err= 0", fio_randread)
            fio_write = device.run_fio_dictionary(FIO_WRITE)
            print(fio_write)
            self.assertIn("err= 0", fio_write)
            fio_readwrite = device.run_fio_dictionary(FIO_READWRITE)
            print(fio_readwrite)
            self.assertIn("err= 0", fio_readwrite)
            fio_randwrite = device.run_fio_dictionary(FIO_RANDWRITE)
            print(fio_randwrite)
            self.assertIn("err= 0", fio_randwrite)
            fio_read = device.run_fio_dictionary(FIO_READ)
            print(fio_read)
            self.assertIn("err= 0", fio_read)
            fio_trim = device.run_fio_dictionary(FIO_TRIM)
            print(fio_trim)
            self.assertIn("err= 0", fio_trim)

    def tearDown(self):
        self.ipu_storage_platform.clean()
        self.storage_target_platform.clean()
        self.host_target_platform.clean()
