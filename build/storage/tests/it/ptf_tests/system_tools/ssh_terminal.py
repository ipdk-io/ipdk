# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from paramiko.client import SSHClient, AutoAddPolicy


class SSHTerminal:
    """A class used to represent a session with an SSH server"""

    def __init__(self, config, *args, **kwargs):
        self.config = config
        self.client = SSHClient()

        self.client.load_system_host_keys()
        self.client.set_missing_host_key_policy(AutoAddPolicy)
        self.client.connect(config.ip_address, config.port, config.username, config.password, *args, **kwargs)

    def execute(self, cmd: str, timeout: int = None) -> list:
        """ Simple function executes a command on the SSH server
        Return list of the lines output
        """

        _, stdout, stderr = self.client.exec_command(cmd, timeout=timeout)
        assert not stdout.channel.recv_exit_status()
        #  if command is executed in the background don't wait for the output
        out = [] if cmd.rstrip().endswith("&") else stdout.readlines()
        return [line.rstrip() for line in out]

    def delete_all_containers(self):
        """Delete all containers even currently running"""
        out = self.execute('docker ps -aq')
        if out:
            self.execute('docker container rm -fv $(docker ps -aq)')
