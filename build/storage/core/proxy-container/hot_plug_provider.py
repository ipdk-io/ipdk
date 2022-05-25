#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from multiprocessing.sharedctypes import Value
import os.path
import errno
import subprocess
from pathlib import Path


class ActionExecutionError(RuntimeError):
    def __init__(self, message):
        super().__init__(message)


class HotPlugProvider:
    def __init__(self, shared_dir_path, host_shared_dir_path):
        if shared_dir_path == None:
            raise ValueError("shared_dir_path value cannot be None")
        if host_shared_dir_path == None:
            raise ValueError("host_shared_dir_path value cannot be None")
        self.shared_dir_path = shared_dir_path
        self.host_shared_dir_path = host_shared_dir_path

    def _hot_plug_action(self, vm_monitor, vhost_virtio_blk, device_id):
        vm_monitor_path = os.path.join(self.shared_dir_path, vm_monitor)
        vhost_path = os.path.join(self.host_shared_dir_path, vhost_virtio_blk)
        ret = subprocess.call(
            "/hot-plug.sh " + vm_monitor_path + " " + vhost_path + " " + str(device_id),
            shell=True,
        )
        if ret != 0:
            raise ActionExecutionError("Error at hot-plug execution")

    def _hot_unplug_action(self, vm_monitor, unused, device_id):
        vm_monitor_path = os.path.join(self.shared_dir_path, vm_monitor)
        ret = subprocess.call(
            "/hot-unplug.sh " + vm_monitor_path + " " + str(device_id), shell=True
        )
        if ret != 0:
            raise ActionExecutionError("Error at hot-unplug execution")

    def _adjust_vm_monitor(vm_monitor):
        return vm_monitor.strip()

    def _adjust_vhost_virtio_blk(vhost_virtio_blk):
        return vhost_virtio_blk.strip()

    def __is_socket(socket_path):
        return Path(socket_path).is_socket()

    def __check_socket_path(path):
        if not HotPlugProvider.__is_socket(path):
            raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), path)

    def _validate_vhost_virtio_blk(self, vhost_virtio_blk):
        HotPlugProvider.__check_socket_path(
            os.path.join(self.shared_dir_path, vhost_virtio_blk)
        )

    def _validate_vm_monitor(self, vm_monitor):
        HotPlugProvider.__check_socket_path(
            os.path.join(self.shared_dir_path, vm_monitor)
        )

    def _validate_input(self, vm_monitor, vhost_virtio_blk):
        self._validate_vhost_virtio_blk(vhost_virtio_blk)
        self._validate_vm_monitor(vm_monitor)

    def _generate_device_id(self, vhost_virtio_blk):
        return vhost_virtio_blk.strip()

    def _perform_disk_operation(self, vm_monitor, vhost_virtio_blk, disk_operation):
        if vm_monitor == None:
            raise ValueError("vm_monitor value cannot be None")
        if vhost_virtio_blk == None:
            raise ValueError("vhost_virtio_blk value cannot be None")

        vm_monitor = HotPlugProvider._adjust_vm_monitor(vm_monitor)
        vhost_virtio_blk = HotPlugProvider._adjust_vhost_virtio_blk(vhost_virtio_blk)

        self._validate_input(vm_monitor, vhost_virtio_blk)

        device_id = self._generate_device_id(vhost_virtio_blk)

        try:
            disk_operation(vm_monitor, vhost_virtio_blk, device_id)
        except BaseException as ex:
            raise ActionExecutionError(str(ex))

    def hot_plug_vhost_virtio_blk(self, vm_monitor, vhost_virtio_blk):
        self._perform_disk_operation(
            vm_monitor, vhost_virtio_blk, self._hot_plug_action
        )

    def hot_unplug_vhost_virtio_blk(self, vm_monitor, vhost_virtio_blk):
        self._perform_disk_operation(
            vm_monitor, vhost_virtio_blk, self._hot_unplug_action
        )
