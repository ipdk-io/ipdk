# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import os
from abc import ABC, abstractmethod
from dotenv import load_dotenv


class BaseConfig(ABC):
    load_dotenv()

    @abstractmethod
    def __init__(self):
        pass


class MainPlatformConfig(BaseConfig):
    def __init__(self):
        self.username = os.getenv("MAIN_PLATFORM_USERNAME")
        self.password = os.getenv("MAIN_PLATFORM_PASSWORD")
        self.ip_address = os.getenv("MAIN_PLATFORM_IP_ADDRESS")
        self.port = os.getenv("MAIN_PLATFORM_PORT", 22)
        self.workdir = os.getenv(
            "MAIN_PLATFORM_WORKDIR", f"/home/{self.username}/workdir"
        )


class StorageTargetConfig(MainPlatformConfig):
    def __init__(self):
        super().__init__()
        username = os.getenv("STORAGE_TARGET_USERNAME")
        if username:
            self.username = username
            self.password = os.getenv("STORAGE_TARGET_PASSWORD")
            self.ip_address = os.getenv("STORAGE_TARGET_IP_ADDRESS")
            self.port = os.getenv("STORAGE_TARGET_PORT", 22)
            self.workdir = os.getenv(
                "STORAGE_TARGET_WORKDIR", f"/home/{self.username}/workdir"
            )


class IPUStorageConfig(MainPlatformConfig):
    def __init__(self):
        super().__init__()
        username = os.getenv("IPU_STORAGE_USERNAME")
        if username:
            self.username = username
            self.password = os.getenv("IPU_STORAGE_PASSWORD")
            self.ip_address = os.getenv("IPU_STORAGE_IP_ADDRESS")
            self.port = os.getenv("IPU_STORAGE_PORT", 22)
            self.workdir = os.getenv(
                "IPU_STORAGE_WORKDIR", f"/home/{self.username}/workdir"
            )


class HostTargetConfig(MainPlatformConfig):
    def __init__(self):
        super().__init__()
        username = os.getenv("HOST_TARGET_USERNAME")
        if username:
            self.username = username
            self.password = os.getenv("HOST_TARGET_PASSWORD")
            self.ip_address = os.getenv("HOST_TARGET_IP_ADDRESS")
            self.port = os.getenv("HOST_TARGET_PORT", 22)
            self.workdir = os.getenv(
                "HOST_TARGET_WORKDIR", f"/home/{self.username}/workdir"
            )
