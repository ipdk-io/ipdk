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


class StorageTargetConfig(BaseConfig):

    def __init__(self):
        self.username = os.getenv('STORAGE_TARGET_USERNAME')
        self.password = os.getenv('STORAGE_TARGET_PASSWORD')
        self.ip_address = os.getenv('STORAGE_TARGET_IP_ADDRESS')
        self.port = os.getenv('STORAGE_TARGET_PORT', 22)


class IPUStorageConfig(BaseConfig):

    def __init__(self):
        self.username = os.getenv('IPU_STORAGE_USERNAME')
        self.password = os.getenv('IPU_STORAGE_PASSWORD')
        self.ip_address = os.getenv('IPU_STORAGE_IP_ADDRESS')
        self.port = os.getenv('IPU_STORAGE_PORT', 22)


class HostTargetConfig(BaseConfig):

    def __init__(self):
        self.username = os.getenv('HOST_TARGET_USERNAME')
        self.password = os.getenv('HOST_TARGET_PASSWORD')
        self.ip_address = os.getenv('HOST_TARGET_IP_ADDRESS')
        self.port = os.getenv('HOST_TARGET_PORT', 22)
