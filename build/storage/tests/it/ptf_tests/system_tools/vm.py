# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import sys

# add build dir to the path
sys.path.append("../../../../..")

import os
import re
import time

from storage.scripts.socket_functions import send_command_over_unix_socket
from tenacity import retry, stop_after_delay

from system_tools.const import (DEFAULT_HOST_TARGET_SERVICE_PORT_IN_VM,
                                DEFAULT_QMP_PORT)
from system_tools.errors import BusyPortException, VirtualizationException


class VirtualMachine:
    def __init__(self, platform):
        # TODO: replace all these default parameters with values from config and change the way
        # how config is delivered to this class
        self.platform = platform
        self.storage_path = platform.get_storage_dir()

        self.platform.terminal.client.exec_command(
            f"mkdir -p {self.platform.terminal.config.vm_share_dir_path}"
        )
        self.socket_path = os.path.join(
            self.platform.terminal.config.vm_share_dir_path, "vm_socket"
        )

    def run(self, login, password):
        self.delete()
        if self.platform.get_pid_from_port(DEFAULT_QMP_PORT):
            raise BusyPortException(f"There is process in {DEFAULT_QMP_PORT} port")
        if os.path.exists(self.socket_path):
            raise VirtualizationException("Socket path is not free")
        cmd = f"SHARED_VOLUME={self.platform.terminal.config.vm_share_dir_path} UNIX_SERIAL=vm_socket scripts/vm/run_vm.sh &> /dev/null &"
        self.platform.terminal.execute(f"cd {self.storage_path} && {cmd}")
        self._wait_to_run(DEFAULT_QMP_PORT)
        self._login(login, password)

    def delete(self):
        if self.platform.get_pid_from_port(DEFAULT_QMP_PORT):
            self.platform.kill_process_from_port(DEFAULT_QMP_PORT)
        if self.platform.get_pid_from_port(DEFAULT_HOST_TARGET_SERVICE_PORT_IN_VM):
            self.platform.kill_process_from_port(DEFAULT_HOST_TARGET_SERVICE_PORT_IN_VM)
        self.platform.terminal.execute(
            f"cd {self.platform.terminal.config.vm_share_dir_path} && rm -rf $(ls)"
        )

    @retry(stop=stop_after_delay(600), reraise=True)
    def _wait_to_run(self, port):
        time.sleep(30)
        if not self.platform.get_pid_from_port(port) or not os.path.exists(
            self.socket_path
        ):
            raise VirtualizationException("VM is not running")
        time.sleep(60)

    def _login(self, login, password):
        # TODO create UnixSocketTerminal
        send_command_over_unix_socket(self.socket_path, login, 1)
        send_command_over_unix_socket(self.socket_path, password, 1)

    def get_number_of_virtio_blk_devices(self):
        cmd = "ls -1 /dev"
        out = send_command_over_unix_socket(
            sock=self.socket_path, cmd=cmd, wait_for_secs=1
        )
        return len(re.findall("vd[a-z]+\\b", out))
