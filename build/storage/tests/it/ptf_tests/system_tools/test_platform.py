class HostPlatform:
    """
    A class used to represent a setup of a machine

    ...

    Attributes
    ----------
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


    def __init__(self, terminal):
        """
        Parameters
        ----------
        terminal: ExtendedTerminal
            A session with an SSH server
        """

        self.terminal = terminal
        self.pms = 'dnf' if self._is_dnf() else 'apt-get' if self._is_apt() else None
        self.system = self._os_system()

    def _os_system(self):
        return self.terminal.execute("sudo cat /etc/os-release | grep ^ID=")[0][3:]

    def _is_dnf(self):
        _, stdout, _ = self.terminal.terminal.exec_command("dnf --version")
        return not stdout.channel.recv_exit_status()

    def _is_apt(self):
        _, stdout, _ = self.terminal.terminal.exec_command("apt-get --version")
        return not stdout.channel.recv_exit_status()

    def _is_virtualization(self) -> bool:
        """
        Checks if VT-x/AMD-v support is enabled in BIOS

        Returns
        -------
        bool
            True if virtualization support is enabled in BIOS else False
        """

        expectations = ["vt-x", "amd-v", "full"]
        out = self.terminal.execute("lscpu | grep -i virtualization")[0]
        for allowed_str in expectations:
            if allowed_str.upper() in out.upper():
                return True
        return False

    def _is_kvm(self) -> bool:
        """
        Checks if kvm modules are loaded

        Returns
        -------
        bool
            True if kvm modules are loaded else False
        """

        expectations = ["kvm_intel", "kvm_amd"]
        out = self.terminal.execute("lsmod | grep -i kvm")[0]
        for allowed_str in expectations:
            if allowed_str.upper() in out.upper():
                return True
        return False

    # todo
    def _is_quemu(self):
        return True

    def _install_libguestfs_tools(self) -> bool:
        """
        Installs libguestfs-tools for a specific OS

        Returns
        -------
        bool
            True if installation is successful else False
        """

        program = "libguestfs-tools" if self.system == 'ubuntu' else "libguestfs-tools-c"
        out = self.terminal.execute(f"sudo {self.pms} install -y {program}")
        return bool(out)

    def _install_wget(self) -> bool:
        out = self.terminal.execute(f"sudo {self.pms} install -y wget")
        return bool(out)

    def _change_vmlinuz(self) -> bool:
        """
        Changes the mode of /boot/vmlinuz-*

        Returns
        -------
        bool
            True if change is successful else False
        """

        _, stdout, stderr = self.terminal.terminal.exec_command("sudo chmod +r /boot/vmlinuz-*")
        return not stdout.read().decode() or stderr.read().decode()

    def _set_security_policies(self) -> bool:
        cmd = "sudo setenforce 0" if self.system == "fedora" else "sudo systemctl stop apparmor"
        _, stdout, stderr = self.terminal.terminal.exec_command(cmd)
        return "disabled" in stdout.read().decode() or "disabled" in stderr.read().decode()

    def _is_installed_docker_dependencies(self):
        cmds = ("docker --version", "wget --version", "docker-compose --version")
        for cmd in cmds:
            out = self.terminal.execute(cmd)
            if not out:
                return False
        return True

    def host_system_setup(self):
        assert self._is_virtualization()
        assert self._is_kvm()
        assert self.pms
        assert self._is_quemu()
        assert self._set_security_policies()
        assert self._is_installed_docker_dependencies()
        assert self._change_vmlinuz()
