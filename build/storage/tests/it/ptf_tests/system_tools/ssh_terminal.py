# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from paramiko.client import SSHClient, AutoAddPolicy


class CommandError(Exception):
    """A custom Exception of a Terminal class raised when an error during command execution occurs"""


class SSHTerminal:
    """
    A class used to represent a session with an SSH server

    ...

    Attributes
    ----------
    terminal: BaseTerminal
        A high-level representation of a session with an SSH server

    Methods
    -------
    execute(cmd, cwd=None, timeout=None, raise_on_error=True)
        Executes a command on an SSH server within a specific directory equal to cwd (default None)
        with given timeout (default None) and raises an error if a command execution fails and
        raise_on_error is equal to True (default True)
    """

    def __init__(self, config, *args, **kwargs):
        """
        Parameters
        ----------
        terminal: BaseTerminal
        A high-level representation of a session with an SSH server
        """

        self.config = config
        self.client = SSHClient()

        self.client.load_system_host_keys()
        self.client.set_missing_host_key_policy(AutoAddPolicy)
        self.client.connect(config.ip_address, config.port, config.username, config.password, *args, **kwargs)

    def execute(
        self,
        cmd: str,
        timeout: int = None,
    ) -> list:
        """
        Simple function executes a command on the SSH server

        Parameters
        ----------
        cmd: str
            The command to execute

        Returns
        -------
        list(str)
            The list of the lines output
        """

        _, stdout, stderr = self.client.exec_command(cmd, timeout=timeout)
        assert not stdout.channel.recv_exit_status()
        #  if command is executed in the background don't wait for the output
        out = [] if cmd.rstrip().endswith("&") else stdout.readlines()
        return [line.rstrip() for line in out]

    def delete_all_containers(self):
        out = self.execute('docker ps -aq')
        if out:
            self.execute('docker container rm -fv $(docker ps -aq)')
