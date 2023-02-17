# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import time

from tenacity import retry, stop_after_delay

from system_tools.config import (HostTargetConfig, IPUStorageConfig,
                                 StorageTargetConfig, TestConfig)
from system_tools.const import DEFAULT_HOST_TARGET_SERVICE_PORT_IN_VM
from system_tools.errors import ContainerNotRunningException
from system_tools.ssh_terminal import SSHTerminal


class Docker:
    def __init__(self, terminal):
        self.terminal = terminal
        self.containers = {}

    def get_docker_containers_id_from_docker_image_name(self, docker_image_name):
        out = self.terminal.execute(
            f'sudo docker ps | grep "{docker_image_name}"'
        ).splitlines()
        return [line.split()[0] for line in out]

    def _delete_all_containers(self):
        """Delete all containers even currently running"""
        out = self.terminal.execute("docker ps -aq")
        if out:
            self.terminal.execute("docker container rm -fv $(docker ps -aq)")

    def _delete_running_containers(self):
        """Delete running containers"""
        for container in self.containers.values():
            container.stop()

    def delete_containers(self):
        """Delete containers"""
        return (
            self._delete_all_containers()
            if TestConfig().debug.upper() == "FALSE"
            else self._delete_running_containers()
        )

    def add_container(self, name, container_id):
        self.containers[name] = container_id


class DockerContainer:
    def __init__(self, terminal, cmd_to_start, image_name):
        self.image_name = image_name
        self._terminal = terminal
        self._cmd_to_start = cmd_to_start
        self.id = None
        self.start()

    def start(self):
        out = self._terminal.execute(self._cmd_to_start)
        self._wait_for_running(self.image_name)
        self.id = out.split()[-1].strip("'")
        return self.id

    def stop(self):
        self._terminal.execute(f"docker container rm -fv {self.id}")

    @retry(stop=stop_after_delay(180), reraise=True)
    def _wait_for_running(self, image_name):
        out = self._terminal.execute("docker ps")
        if image_name not in out:
            raise ContainerNotRunningException


class StorageTargetContainer(DockerContainer):
    def __init__(self):
        terminal = SSHTerminal(StorageTargetConfig())
        cmd = (
            f"cd {terminal.config.storage_dir} && "
            f"AS_DAEMON=true scripts/run_storage_target_container.sh"
        )
        super().__init__(terminal, cmd, "storage-target")


class IPUStorageContainer(DockerContainer):
    def __init__(self):
        shared_dir = HostTargetConfig().vm_share_dir_path
        terminal = SSHTerminal(IPUStorageConfig())
        cmd = (
            f"cd {terminal.config.storage_dir} && "
            f"AS_DAEMON=true SHARED_VOLUME={shared_dir} "
            f"scripts/run_ipu_storage_container.sh"
        )
        super().__init__(terminal, cmd, "ipu-storage")


class CMDSenderContainer(DockerContainer):
    def __init__(self, config=None):
        terminal = SSHTerminal(config)
        cmd = (
            f"cd {config.storage_dir} && "
            f"AS_DAEMON=true "
            f"scripts/run_cmd_sender.sh"
        )
        super().__init__(terminal, cmd, "cmd-sender")

    def run_fio(self, host_target_id, virtio_blk, fio_args):
        cmd = (
            f"""docker exec {self.id} """
            f"""python -c "from scripts.disk_infrastructure import *; """
            f"""import json; """
            f"""fio={{'diskToExercise': {{'deviceHandle': '{virtio_blk}'}}"""
            f""",'fioArgs': json.dumps({fio_args})}}; """
            f"""print(send_host_target_request(HostTargetServiceMethod.RunFio, fio,"""
            f""" '{host_target_id}', {DEFAULT_HOST_TARGET_SERVICE_PORT_IN_VM}))" """
        )
        return self._terminal.execute(cmd) == "True"

    def create_subsystem(
        self, ip_addr: str, nqn: str, port_to_expose: int, storage_target_port: int
    ):
        return self._terminal.execute(
            f"""docker exec {self.id} """
            f"""python -c "from scripts.disk_infrastructure import create_and_expose_subsystem_over_tcp; """
            f"""create_and_expose_subsystem_over_tcp"""
            f"""('{ip_addr}', '{nqn}', '{port_to_expose}', {storage_target_port})" """
        )

    def create_ramdrives(
        self, number: int, ip_addr: str, nqn: str, storage_target_port: int
    ):
        volumes_ids = []
        for i in range(number):
            cmd = (
                f"""docker exec {self.id} """
                f"""python -c 'from scripts.disk_infrastructure import create_ramdrive_and_attach_as_ns_to_subsystem; """
                f"""print(create_ramdrive_and_attach_as_ns_to_subsystem"""
                f"""("{ip_addr}", "Malloc{i}", 4, "{nqn}", {storage_target_port}))'"""
            )
            volumes_ids.append(self._terminal.execute(cmd))
        return volumes_ids

    def create_ramdrive(
        self, number: int, ip_addr: str, nqn: str, storage_target_port: int
    ):
        cmd = (
            f"""docker exec {self.id} """
            f"""python -c 'from scripts.disk_infrastructure import create_ramdrive_and_attach_as_ns_to_subsystem; """
            f"""print(create_ramdrive_and_attach_as_ns_to_subsystem"""
            f"""("{ip_addr}", "Malloc{number}", 4, "{nqn}", {storage_target_port}))'"""
        )
        return self._terminal.execute(cmd)

    def create_virtio_blk_device(
        self,
        ipu_storage_container_ip: str,
        host_target_address_service,
        volume_id: str,
        physical_id: str,
        storage_target_ip: str,
        port_to_expose,
        nqn,
        sma_port,
    ):
        """
        :return: device handle
        """
        cmd = (
            f"""docker exec {self.id} """
            f"""python -c "from scripts.disk_infrastructure import create_virtio_blk; """
            f"""print(create_virtio_blk"""
            f"""('{ipu_storage_container_ip}', '{sma_port}', '{host_target_address_service.ip_address}', """
            f"""{host_target_address_service.port}, """
            f"""'{volume_id}', '{physical_id}', '0', '{nqn}', """
            f"""'{storage_target_ip}', '{port_to_expose}'))" """
        )
        out = self._terminal.execute(cmd)
        time.sleep(5)
        return out

    def delete_virtio_blk_device(
        self,
        ipu_storage_container_ip,
        host_target_address_service,
        device_handle,
        sma_port,
    ):
        cmd = (
            f"""docker exec {self.id} """
            f"""python -c "from scripts.disk_infrastructure import delete_sma_device; """
            f"""print(delete_sma_device"""
            f"""('{ipu_storage_container_ip}', '{sma_port}', '{host_target_address_service.ip_address}', """
            f"""{host_target_address_service.port}, '{device_handle}'))" """
        )
        return self._terminal.execute(cmd) == "True"


class HostTargetContainer(DockerContainer):
    def __init__(self):
        terminal = SSHTerminal(HostTargetConfig())
        cmd = (
            f"cd {terminal.config.storage_dir} && "
            f"AS_DAEMON=true scripts/run_host_target_container.sh"
        )
        super().__init__(terminal, cmd, "host-target")
