import logging

from paramiko.client import SSHClient, AutoAddPolicy
from tenacity import retry, stop_after_attempt, stop_after_delay


class CommandError(Exception):
    """A custom Exception of a Terminal class raised when an error during command execution occurs"""


class BaseSSHTerminal(SSHClient):
    def __init__(self, ip_address: str, username: str, password: str, port: int = 22):
        super().__init__()
        self.load_system_host_keys()
        self.set_missing_host_key_policy(AutoAddPolicy)
        self._ip_address = ip_address
        self._username = username
        self._password = password
        self._port = port

    @retry(stop=(stop_after_attempt(3) | stop_after_delay(5)), reraise=True)
    def connect(self, *args, **kwargs):
        """
        Initializes an SSH connection to an SSH server
        """

        super().connect(
            self._ip_address,
            self._port,
            self._username,
            self._password,
            *args,
            **kwargs
        )

    def __enter__(self):
        self.connect()
        return self

    def __exit__(self, type, value, traceback):
        self.close()


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

    def __init__(self, terminal: BaseSSHTerminal):
        """
        Parameters
        ----------
        terminal: BaseTerminal
        A high-level representation of a session with an SSH server
        """

        self._terminal = terminal

    def execute(
        self,
        cmd: str,
        cwd: str | None = None,
        timeout: float | None = None,
        raise_on_error: bool = True,
    ) -> tuple[str, int]:
        """
        Executes a command on the SSH server

        Parameters
        ----------
        cmd: str
            The command to execute
        cwd: str | None
            The directory path where command should be executed
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
        TerminalException
            When the execution of the command fails and raise_on_error parameter is equal to True
        """

        if cwd is not None:
            cmd = f"cd {cwd} && {cmd}"

        logging.info(f'Execute command: "{cmd}" with timeout={timeout}')
        with self._terminal:
            _, stdout, stderr = self._terminal.exec_command(cmd, timeout=timeout)
            rc = stdout.channel.recv_exit_status()

        #  if command is executed in the background don't wait for the output
        out = (
            ""
            if cmd.rstrip().endswith("&")
            else (stdout.read() or stderr.read()).decode()
        )

        if raise_on_error and rc:
            raise CommandError(f"Command execution failed\nrc={rc}\nout={out}")
        elif not raise_on_error and rc:
            logging.error(f"Command failed with\nrc={rc}\nout={out}")
        else:
            logging.info(f"Command executed with\nrc={rc}\nout={out}")

        return out, rc
