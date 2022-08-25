import logging
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from typing import Optional

sys.path.append('../')

from python_system_tools.extendedterminal import ExtendedTerminal
from python_system_tools.consts import WORKSPACE_PATH


class UnknownOSError(Exception):
    """A custom Exception of a Setup class"""


class Setup:
    """
    A class used to represent a setup of a machine

    ...

    Attributes
    ----------
    pms: dict
        A dictionary that maps package manager to an operating system
    terminal: ExtendedTerminal
        Represents a session with an SSH server
    os: str
        The name of an operating system
    pm: str
        The name of a package manager

    Methods
    -------
    check_virtualization()
        Checks if VT-x/AMD-v support is enabled in BIOS
    check_kvm()
        Checks if kvm modules are loaded
    check_system()
        Checks the type of OS and returns it, raises UnknownOSError if it's unrecognized
    install(program)
        Installs a program on a machine
    setup_docker_compose()
        Checks if docker-compose is installed and installs it if it's not
    setup_libguestfs_tools()
        Installs libguestfs-tools for a specific OS
    change_vmlinuz()
        Changes the mode of /boot/vmlinuz-*
    check_security_policies()
        Checks if security policies are disabled
    """

    pms = {"Fedora": "dnf", "Ubuntu": "apt"}

    def __init__(self, terminal: ExtendedTerminal):
        """
        Parameters
        ----------
        terminal: ExtendedTerminal
            A session with an SSH server
        """

        self.terminal = terminal
        self.os = self.check_system()
        self.pm = self.pms[self.os]

    def check_virtualization(self) -> bool:
        """
        Checks if VT-x/AMD-v support is enabled in BIOS

        Returns
        -------
        bool
            True if virtualization support is enabled in BIOS else False
        """

        logging.info("Checking if VT-x/AMD-v support is enabled in BIOS")
        regex = re.compile(r"vt-x|amd-v|full", re.IGNORECASE)
        out, _ = self.terminal.execute("lscpu | grep -i virtualization")
        if regex.search(out):
            logging.info("Virtualization support is enabled in BIOS")
            return True
        logging.error("Virtualization support is not enabled in BIOS")
        return False

    def check_kvm(self) -> bool:
        """
        Checks if kvm modules are loaded

        Returns
        -------
        bool
            True if kvm modules are loaded else False
        """

        logging.info("Checking if kvm modules are loaded")
        out, _ = self.terminal.execute("lsmod | grep -i kvm")
        if re.search(r"kvm_intel|kvm_amd", out):
            logging.info("kvm modules are loaded")
            return True
        logging.error("kvm modules are not loaded")
        return False

    def check_system(self) -> Optional[str]:
        """
        Checks if kvm modules are loaded

        Returns
        -------
        str | None
            The name of operating system or None if it's unrecognized

        Raises
        ------
        UnknownOSError
            The error raised when the operating system is unrecognized (different than Fedora or Ubuntu)
        """

        logging.info("Checking operating system")
        out, _ = self.terminal.execute("cat /etc/os-release")
        if match := re.search(r"Fedora|Ubuntu", out):
            logging.info(f"Operating system is {match.group()}")
            return match.group()
        logging.error("Unrecognized operating system")
        raise UnknownOSError("Unsupported OS")

    def install(self, program: str) -> bool:
        """
        Installs a program on a machine

        Parameters
        ----------
        program: str
            The name of a program to install

        Returns
        -------
        bool
            True if program is installed successfully or present on a machine else False
        """

        logging.info(f"Installing {program}")
        out, rc = self.terminal.execute_as_root(f"{self.pm} -y install {program}")
        if rc:
            logging.error(
                f"Installing {program} failed with code {rc} and output {out}"
            )
            return False
        logging.info(f"{program} installed successfully or present on a machine")
        return True

    def setup_docker_compose(self) -> bool:
        """
        Checks if docker-compose is installed and installs it if it's not

        Returns
        -------
        bool
            True if setup is successful or docker-compose is already installed else False
        """

        cmds = (
            'curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose',
            "chmod +x /usr/local/bin/docker-compose",
            "ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
        )
        _, rc = self.terminal.execute("docker-compose --version", raise_on_error=False)
        if rc:
            logging.info("Setting up docker-compose")
            for cmd in cmds:
                out, rc = self.terminal.execute_as_root(cmd)
                if rc:
                    logging.error(
                        f"Setting up docker failed with code {rc} and output {out}"
                    )
                    return False
            logging.info(f"Setup of docker-compose was successful")
            return True
        logging.info(f"docker-compose is already installed")
        return True

    def setup_libguestfs_tools(self) -> bool:
        """
        Installs libguestfs-tools for a specific OS

        Returns
        -------
        bool
            True if installation is successful else False
        """

        program = "libguestfs-tools"
        if self.os == "Fedora":
            program += "-c"
        return self.install(program)

    def change_vmlinuz(self) -> bool:
        """
        Changes the mode of /boot/vmlinuz-*

        Returns
        -------
        bool
            True if change is successful else False
        """

        out, rc = self.terminal.execute_as_root("chmod +r /boot/vmlinuz-*")
        if rc:
            logging.error(
                f"Changing the mode of /boot/vmlinuz-* failed with code {rc} and output {out}"
            )
            return False
        logging.info("Mode of /boot/vmlinuz-* was changed")
        return True

    def check_security_policies(self) -> bool:
        """
        Checks if security policies are disabled

        Returns
        -------
        bool
            True if security policies are disabled else False
        """

        if self.os == "Fedora":
            cmd = "setenforce 0"
        else:
            cmd = "systemctl stop apparmor"
        out, rc = self.terminal.execute_as_root(cmd, raise_on_error=False)
        if "disabled" in out:
            logging.info("Security policies are disabled")
            return True
        logging.error(
            f"Disabling security policies failed with code {rc} and output {out}"
        )
        return False

    def clone_repo(self, branch=None):
        self.terminal.mkdir(WORKSPACE_PATH)
        if branch:
            return self.terminal.execute_as_root(
                f"git clone -b {branch} https://github.com/ipdk-io/ipdk.git",
                cwd=WORKSPACE_PATH,
            )
        else:
            return self.terminal.execute_as_root(
                "git clone https://github.com/ipdk-io/ipdk.git",
                cwd=WORKSPACE_PATH,
            )

    def is_installed(self):
        cmds = ("docker --version", "wget --version", "docker-compose --version")
        rcs = [self.terminal.execute(cmd)[1] for cmd in cmds]
        return rcs

    @staticmethod
    def setup_on_both_machines(
        function1, function2, args1=[], args2=[], kwargs1={}, kwargs2={}, timeout=None
    ):
        with ThreadPoolExecutor() as executor:
            future_storage = executor.submit(function1, *args1, **kwargs1)
            future_proxy = executor.submit(function2, *args2, **kwargs2)
            return_values = (
                future_storage.result(timeout=timeout),
                future_proxy.result(timeout=timeout),
            )
        return return_values