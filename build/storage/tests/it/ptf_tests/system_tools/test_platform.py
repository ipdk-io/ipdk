# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
from system_tools.ssh_terminal import SSHTerminal


class HostPlatform:
    """A class used to represent a setup of a machine"""

    def __init__(self, terminal: SSHTerminal):
        self.terminal = terminal
        self.pms = "dnf" if self._is_dnf() else "apt-get" if self._is_apt() else None
        self.system = self._os_system()

    def _os_system(self) -> str:
        return self.terminal.execute("sudo cat /etc/os-release | grep ^ID=")[0][3:]

    def _is_dnf(self) -> bool:
        _, stdout, _ = self.terminal.client.exec_command("dnf --version")
        return not stdout.channel.recv_exit_status()

    def _is_apt(self) -> bool:
        _, stdout, _ = self.terminal.client.exec_command("apt-get --version")
        return not stdout.channel.recv_exit_status()

    def _is_docker(self) -> bool:
        _, stdout, _ = self.terminal.client.exec_command("docker --version")
        return not stdout.channel.recv_exit_status()

    def _is_docker_compose(self) -> bool:
        _, stdout, _ = self.terminal.client.exec_command("docker-compose --version")
        return not stdout.channel.recv_exit_status()

    def _is_virtualization(self) -> bool:
        """Checks if VT-x/AMD-v support is enabled in BIOS"""

        expectations = ["vt-x", "amd-v", "full"]
        out = self.terminal.execute("lscpu | grep -i virtualization")[0]
        for allowed_str in expectations:
            if allowed_str.upper() in out.upper():
                return True
        return False

    def _is_kvm(self) -> bool:
        """Checks if kvm modules are loaded"""

        expectations = ["kvm_intel", "kvm_amd"]
        out = self.terminal.execute("lsmod | grep -i kvm")[0]
        for allowed_str in expectations:
            if allowed_str.upper() in out.upper():
                return True
        return False

    # todo
    def _is_quemu(self) -> bool:
        return True

    def _install_libguestfs_tools(self) -> bool:
        """Installs libguestfs-tools for a specific OS"""

        program = (
            "libguestfs-tools" if self.system == "ubuntu" else "libguestfs-tools-c"
        )
        out = self.terminal.execute(f"sudo {self.pms} install -y {program}")
        return bool(out)

    def _install_wget(self) -> bool:
        out = self.terminal.execute(f"sudo {self.pms} install -y wget")
        return bool(out)

    def _change_vmlinuz(self) -> bool:
        """Changes the mode of /boot/vmlinuz-*"""

        _, stdout, stderr = self.terminal.client.exec_command(
            "sudo chmod +r /boot/vmlinuz-*"
        )
        return not stdout.read().decode() or stderr.read().decode()

    def _set_security_policies(self) -> bool:
        cmd = (
            "sudo setenforce 0"
            if self.system == "fedora"
            else "sudo systemctl stop apparmor"
        )
        _, stdout, stderr = self.terminal.client.exec_command(cmd)
        return (
            "disabled" in stdout.read().decode() or "disabled" in stderr.read().decode()
        )

    def _is_installed_docker_dependencies(self) -> bool:
        cmds = ("docker --version", "wget --version", "docker-compose --version")
        for cmd in cmds:
            out = self.terminal.execute(cmd)
            if not out:
                return False
        return True

    def _install_docker_compose(self):
        """Checks if docker-compose is installed and installs it if it's not
        True if setup is successful or docker-compose is already installed else False
        """
        cmds = (
            'curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose',
            "chmod +x /usr/local/bin/docker-compose",
            "ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
        )
        if not self._is_docker():
            for cmd in cmds:
                self.terminal.execute(cmd)

    # TODO
    def _install_docker(self):
        pass

    def host_system_setup(self):
        assert self._is_virtualization()
        assert self._is_kvm()
        assert self.pms
        assert self._is_quemu()
        assert self._set_security_policies()
        assert self._is_installed_docker_dependencies()
        assert self._change_vmlinuz()
        if not self._is_docker():
            self._install_docker()
        assert self._is_docker()
        if not self._is_docker_compose():
            self._install_docker_compose()
        assert self._is_docker_compose()
