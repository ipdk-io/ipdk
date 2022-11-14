# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from system_tools.config import (
    HostTargetConfig,
    IPUStorageConfig,
    StorageTargetConfig,
)
from system_tools.ssh_terminal import SSHTerminal


class BaseTestPlatform:
    """A base class used to represent operating system with needed libraries"""

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

    # TODO add implementation
    def _is_qemu(self) -> bool:
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

    # TODO add implementation
    def _install_docker(self):
        pass

    def check_system_setup(self):
        """Overwrite this method in specific platform if you don't want check all setup"""
        if not self._is_virtualization():
            raise Exception("Virtualization is not setting properly")
        if not self._is_kvm():
            raise Exception("KVM is not setting properly")
        if not self.pms:
            raise Exception("Packet manager is not setting properly")
        if not self._is_qemu():
            raise Exception("QUEMU is not setting properly")
        if not self._set_security_policies():
            raise Exception("Security polices is not setting properly")
        if not self._is_docker():
            raise Exception("Docker is not setting properly")

    # TODO: after testing restore settings
    def set_system_setup(self):
        """Overwrite this method in specific platform if you don't want set all setup"""
        self._change_vmlinuz()
        if not self._is_docker():
            self._install_docker()


class StorageTargetPlatform(BaseTestPlatform):
    def __init__(self):
        config = StorageTargetConfig()
        terminal = SSHTerminal(config)
        super().__init__(terminal)

    # TODO add implementation
    def create_subsystem(self):
        pass

    # TODO add implementation
    def create_ramdrive(self):
        return "Guid"


class IPUStoragePlatform(BaseTestPlatform):
    def __init__(self):
        config = IPUStorageConfig()
        terminal = SSHTerminal(config)
        super().__init__(terminal)

    # TODO add implementation
    def create_virtio_blk_device(self):
        return "VirtioBlkDevice"


class HostTargetPlatform(BaseTestPlatform):
    def __init__(self):
        config = HostTargetConfig()
        terminal = SSHTerminal(config)
        super().__init__(terminal)

    # TODO add implementation
    def run_fio(self):
        return "FioOutput"

    # TODO add implementation
    def check_number_of_virtio_blks(self):
        return "int"
