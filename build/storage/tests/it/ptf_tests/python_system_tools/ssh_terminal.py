# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from paramiko.client import SSHClient, AutoAddPolicy
from tenacity import retry, stop_after_attempt, stop_after_delay


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
        self.terminal = SSHClient()

        self.terminal.load_system_host_keys()
        self.terminal.set_missing_host_key_policy(AutoAddPolicy)
        self.terminal.connect(config.ip_address, config.port, config.username, config.password, *args, **kwargs)

    def execute(
        self,
        cmd: str,
        timeout: float = None,
    ) -> tuple[str, int]:
        """
        Simple function executes a command on the SSH server

        Parameters
        ----------
        cmd: str
            The command to execute
        timeout: float | None
            Set command's channel timeout (default None)

        Returns
        -------
        list(str)
            The list of the lines output
        """

        _, stdout, stderr = self.terminal.exec_command(cmd, timeout=timeout)
        #  if command is executed in the background don't wait for the output
        out = [] if cmd.rstrip().endswith("&") else stdout.readlines() or stderr.readlines()
        result = map(lambda x: x[:-1], out)
        return list(result)
