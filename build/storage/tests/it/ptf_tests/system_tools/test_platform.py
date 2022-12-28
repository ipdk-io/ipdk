# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from system_tools.config import (HostTargetConfig, IPUStorageConfig,
                                 StorageTargetConfig)
from system_tools.docker import (CMDSenderContainer, Docker,
                                 HostTargetContainer, IPUStorageContainer,
                                 StorageTargetContainer)
from system_tools.errors import MissingDependencyException
from system_tools.ssh_terminal import SSHTerminal
from system_tools.vm import VirtualMachine


class RemoteNvmeStorage:
    """Helper class
    self.guid: volume_id
    self.nqn: subsystem nqn
    """

    def __init__(self, ip_address, port, nqn, guid):
        self.nvme_controller_address = ServiceAddress(ip_address, port)
        self.guid = guid
        self.nqn = nqn


class ServiceAddress:
    """storage_target_ip + nvme_port"""

    def __init__(self, ip_address, port):
        self.ip_address = ip_address
        self.port = port


class IpuStorageDevice:
    def __init__(
        self,
        device_handle,
        ipu_platform,
    ):
        self._device_handle = device_handle
        self._ipu_platform = ipu_platform

    # def run_fio(self):
    #     cmd_sender_id = self._ipu_platform.cmd_sender.id
    #     cmd = f"""docker exec {cmd_sender_id} grpc_cli call {self._ipu_platform.get_ip_address()}:50051 RunFio""" \
    #           f""" "diskToExercise: {{ deviceHandle: '{self._device_handle}' }} fioArgs: """ \
    #           f"""'{{\\"rw\\":\\"randrw\\", \\"runtime\\":1, \\"numjobs\\": 1, \\"time_based\\": 1, """ \
    #           f"""\\"group_reporting\\": 1 }}'" """
    #     print(cmd)
    #     return self._ipu_platform.terminal.execute(cmd)

    def run_fio_dict(self):
        x = '\\"rw\\"'
        y = '\\"randrw\\"'
        fio_params = {
            '\\"rw\\"': "randrw",
            "runtime": 1,
            "numjobs": 1,
            "time_based": 1,
            "group_reporting": 1
        }
        cmd_sender_id = self._ipu_platform.cmd_sender.id
        cmd = f"""docker exec {cmd_sender_id} grpc_cli call {self._ipu_platform.get_ip_address()}:50051 RunFio """ \
              f"""\"diskToExercise: {{deviceHandle:'{self._device_handle}'}} """ \
              f"fioArgs: " \
              f"""\'{{{x}:{y}, \\"runtime\\":\\"1\\", \\"numjobs\\":\\"1\\", \\"time_based\\":\\"1\\"}}\'\""""

        # cmd += f"""\'{{"rw":"randrw", "runtime":"1", "numjobs":"1", "timebased":"1"}}\'\""""
        # for key, value in fio_params.items():
        #     add = ("\"" + key + "\":\"" + value+"\" ")
        #
        #     cmd += add
        # cmd += "\""
        print(cmd)
        return self._ipu_platform.terminal.execute(cmd)


class VirtioBlkDevice(IpuStorageDevice):
    def __init__(
        self,
        device_handle,
        remote_nvme_storage,
        ipu_platform,
        host_target_address_service,
    ):
        super().__init__(device_handle, ipu_platform)
        self._remote_nvme_storage = remote_nvme_storage
        self._host_target_address_service = host_target_address_service

    def delete(self, cmd_sender):
        return cmd_sender.delete_virtio_blk_device(
            self._ipu_platform.get_ip_address(),
            self._host_target_address_service,
            self._device_handle,
            self._ipu_platform.sma_port,
        )


class BaseTestPlatform:
    """A base class used to represent operating system with needed libraries"""

    def __init__(self, terminal, cmd_sender=None):
        self.terminal = terminal
        self.config = self.terminal.config
        self.pms = "dnf" if self._is_dnf() else "apt-get" if self._is_apt() else None
        self.system = self._os_system()
        self.docker = Docker(terminal)
        self.cmd_sender = cmd_sender

    def get_ip_address(self):
        return self.config.ip_address

    def get_storage_dir(self):
        return self.config.storage_dir

    def _os_system(self) -> str:
        return self.terminal.execute("sudo cat /etc/os-release | grep ^ID=")[3:]

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
        out = self.terminal.execute("lscpu | grep -i virtualization")
        for allowed_str in expectations:
            if allowed_str.upper() in out.upper():
                return True
        return False

    def _is_kvm(self) -> bool:
        """Checks if kvm modules are loaded"""

        expectations = ["kvm_intel", "kvm_amd"]
        out = self.terminal.execute("lsmod | grep -i kvm")
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
            raise MissingDependencyException("Virtualization may not be set properly")
        if not self._is_kvm():
            raise MissingDependencyException("KVM may not be set properly")
        if not self.pms:
            raise MissingDependencyException("Packet manager may not be installed")
        if not self._is_qemu():
            raise MissingDependencyException("QUEMU may not be set properly")
        if not self._set_security_policies():
            raise MissingDependencyException("Security polices may not be set properly")
        if not self._is_docker():
            raise MissingDependencyException("Docker may not be installed")

    def get_pid_from_port(self, port: int):
        return self.terminal.execute(
            f"sudo netstat -anop | grep -Po ':{port}\s.*LISTEN.*?\K\d+(?=/)' || true"
        )

    def kill_process_from_port(self, port: int):
        """Raise error if there is no process occupying specific port"""
        pid = self.get_pid_from_port(port)
        self.terminal.execute(f"sudo kill -9 {pid}")

    def clean(self):
        self.cmd_sender.stop()
        self.docker.delete_containers()

    def is_port_free(self, port):
        return not bool(
            self.terminal.execute(f"sudo netstat -anop | grep ':{port} ' || true")
        )

    def is_app_listening_on_port(self, app_name, port):
        out = self.terminal.execute(f"sudo netstat -anop | grep ':{port} ' || true")
        return "spdk_tgt" in out


class StorageTargetPlatform(BaseTestPlatform):
    def __init__(self, cmd_sender=None):
        super().__init__(SSHTerminal(StorageTargetConfig()), cmd_sender)
        self.docker.add_container("storage_target_container", StorageTargetContainer())

    def create_subsystem(self, nqn: str, port_to_expose: int, storage_target_port: int):
        return self.cmd_sender.create_subsystem(
            self.get_ip_address(),
            nqn,
            port_to_expose,
            storage_target_port,
        )

    def create_ramdrives(self, ramdrives_number, port, nqn, spdk_port):
        nvme_storages = []
        for i in range(ramdrives_number):
            nvme_storage = RemoteNvmeStorage(
                self.get_ip_address(),
                port,
                nqn,
                self.cmd_sender.create_ramdrive(
                    i, self.get_ip_address(), nqn, spdk_port
                ),
            )
            nvme_storages.append(nvme_storage)
        return nvme_storages


class IPUStoragePlatform(BaseTestPlatform):
    def __init__(self, cmd_sender=None):
        super().__init__(SSHTerminal(IPUStorageConfig()), cmd_sender)
        self.docker.add_container("ipu_storage_container", IPUStorageContainer())

    @property
    def sma_port(self):
        return self.config.sma_port

    def create_virtio_blk_devices(
        self,
        host_target_address_service,
        volumes,
        physical_ids,
    ):
        device_handles = []
        for volume, physical_id in zip(volumes, physical_ids):
            device_handles.append(
                VirtioBlkDevice(
                    self.cmd_sender.create_virtio_blk_device(
                        self.get_ip_address(),
                        host_target_address_service,
                        volume.guid,
                        physical_id,
                        volume.nvme_controller_address.ip_address,
                        volume.nvme_controller_address.port,
                        volume.nqn,
                        self.sma_port,
                    ),
                    volume,
                    self,
                    host_target_address_service,
                )
            )
        return device_handles

    def create_virtio_blk_devices_sequentially(
        self,
        host_target_address_service,
        volumes,
    ):
        return self.create_virtio_blk_devices(
            host_target_address_service,
            volumes,
            range(len(volumes)),
        )

    def delete_virtio_blk_devices(self, devices_handles):
        for device_handle in devices_handles:
            device_handle.delete(self.cmd_sender)

    def clean(self):
        # TODO delete all alocated devices
        return super().clean()


class HostTargetPlatform(BaseTestPlatform):
    def __init__(self, cmd_sender=None):
        super().__init__(SSHTerminal(HostTargetConfig()), cmd_sender)
        self.docker.add_container("host_target_container", HostTargetContainer())
        self.vm = VirtualMachine(self)
        self.vm.run("root", "root")

    def get_number_of_virtio_blk_devices(self):
        return self.vm.get_number_of_virtio_blk_devices()

    def clean(self):
        super().clean()
        self.vm.delete()

    def host_target_service_port_in_vm(self):
        return self.config.host_target_service_port_in_vm

    def get_service_address(self):
        return ServiceAddress(
            self.get_ip_address(), self.host_target_service_port_in_vm()
        )


class PlatformFactory:
    def __init__(self, cmd_sender_platform_name):
        if cmd_sender_platform_name == "ipu":
            self.cmd_sender = CMDSenderContainer(IPUStorageConfig())
        elif cmd_sender_platform_name == "storage-target":
            self.cmd_sender = CMDSenderContainer(StorageTargetConfig())
        elif cmd_sender_platform_name == "host":
            self.cmd_sender = CMDSenderContainer(HostTargetConfig())
        else:
            assert False

    def create_ipu_storage_platform(self):
        return IPUStoragePlatform(self.cmd_sender)

    def create_storage_target_platform(self):
        return StorageTargetPlatform(self.cmd_sender)

    def create_host_target_platform(self):
        return HostTargetPlatform(self.cmd_sender)
