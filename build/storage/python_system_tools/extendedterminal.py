import logging
import time
from typing import Tuple, Optional

from paramiko.client import SSHClient, AutoAddPolicy
from paramiko.ssh_exception import SSHException


class ExtendedTerminalException(Exception):
    """A custom Exception of an ExtendedTerminal class"""


class ExtendedTerminal:
    """
    A class used to represent a session with an SSH server

    ...

    Attributes
    ----------
    address: str
        An IP address of an SSH server
    user: str
        A user's name
    password: str
        A user's password
    terminal: SSHClient
        A high-level representation of a session with an SSH server

    Methods
    -------
    initialize_terminal(address, user, password)
        Initializes an SSH connection to an SSH server with given address, using given credentials
    disconnect()
        Closes an SSH session
    execute(cmd, timeout=None, raise_on_error=True)
        Executes a command on an SSH server with given timeout (default None) and
        raises an error if a command execution fails and raise_on_error is equal to True (default True)
    execute_as_root(cmd, cwd=None, raise_on_error=None)
        Executes a command on an SSH server as a root within given directory (default None) and
        raises an error if a command execution fails and raise_on_error is equal to True (default True)
    mkdir(path, parents=True)
        Makes an empty directory
    """

    def __init__(self, address: str, user: str, password: str):
        """
        Parameters
        ----------
        address: str
            An IP address of an SSH server
        user: str
            A user's name
        password: str
            A user's password
        """

        self.address = address
        self.user = user
        self.password = password
        self.terminal: SSHClient = self.initialize_terminal(
            address=self.address, password=self.password, user=self.user
        )

    @staticmethod
    def initialize_terminal(address: str, user: str, password: str) -> SSHClient:
        """
        Initializes an SSH connection to an SSH server with given address, using given credentials

        Parameters
        ----------
        address: str
            An IP address of an SSH server
        user: str
            A user's name
        password: str
            A user's password

        Returns
        -------
        SSHClient
            A high-level representation of a session with an SSH server
        """

        terminal = SSHClient()
        terminal.load_system_host_keys()
        terminal.set_missing_host_key_policy(AutoAddPolicy)

        max_attempt = 3
        delay = 5
        for attempt in range(max_attempt):
            try:
                terminal.connect(hostname=address, username=user, password=password)
                break
            except SSHException:
                logging.warning(
                    f"Could not connect to pppd through tunnel. Attempts left: {max_attempt - attempt}"
                )
                attempt_delay = delay * attempt
                logging.info(f"Delaying next attempt for {attempt_delay} seconds")
                time.sleep(attempt_delay)
        return terminal

    def disconnect(self) -> None:
        """Closes an SSH session"""

        self.terminal.close()

    def execute(
            self, cmd: str, timeout: Optional[float] = None, raise_on_error: bool = True
    ) -> Tuple[str, int]:
        """
        Executes a command on the SSH server

        Parameters
        ----------
        cmd: str
            The command to execute
        timeout: float | None
            Set command's channel timeout (default None)
        raise_on_error: bool
            Specify if error is raised when the command execution fails (default True)

        Returns
        -------
        tuple(str, int)
            The tuple of the output and return code of the executed command

        Raises
        ------
        ExtendedTerminalException
            When the execution of the command fails and raise_on_error parameter is equal to True
        """

        logging.info(f'Execute command: "{cmd}" with timeout={timeout}')
        _, stdout, stderr = self.terminal.exec_command(cmd, timeout=timeout)
        rc = stdout.channel.recv_exit_status()

        #  if command is executed in the background don't wait for the output
        out = "" if cmd.rstrip().endswith("&") else (stdout.read() or stderr.read()).decode()

        if raise_on_error and rc:
            raise ExtendedTerminalException(f"Command execution failed")
        elif not raise_on_error and rc:
            logging.error(f"Command failed with\nrc={rc}\nout={out}")
        else:
            logging.info(f"Command executed with\nrc={rc}\nout={out}")

        return out, rc

    def execute_as_root(
            self, cmd: str, cwd: Optional[str] = None, raise_on_error: bool = True
    ) -> Tuple[str, int]:
        """
        Executes a command on the SSH server as root

        Parameters
        ----------
        cmd: str
            The command to execute
        cwd: str | None
            Set the directory in which the command should be executed (default None)
        raise_on_error: bool
            Specify if error is raised when the command execution fails (default True)

        Returns
        -------
        tuple(str, int)
            The tuple of the output and return code of the executed command

        Raises
        ------
        ExtendedTerminalException
            When the execution of the command fails and raise_on_error parameter is equal to True
        """

        if cwd:
            return self.execute(f"cd {cwd} && sudo {cmd}", raise_on_error=raise_on_error)
        return self.execute(f"sudo {cmd}", raise_on_error=raise_on_error)

    def mkdir(self, path: str, parents: bool = True) -> None:
        """Creates an empty directory with given path or nested directories if parents is set to True"""

        infix = "-p" if parents else ""
        cmd = f"mkdir {infix} {path}"
        self.execute(cmd)