import os
import sys
import logging
from typing import List


sys.path.append('../')

from python_system_tools.consts import WORKSPACE_PATH
from python_system_tools.extendedterminal import ExtendedTerminal
from python_system_tools.setup import Setup
from python_system_tools.data import ip_address_proxy, ip_address_storage, ip_address_cmd_sender, user_name, password


class ContainersDeploy:
    """
    A class used to represent a deployment of the storage and proxy containers

    ...

    Attributes
    ----------
    proxy_terminal: ExtendedTerminal
        A session with an SSH server on a proxy target
    storage_terminal: ExtendedTerminal
        A session with an SSH server on a storage target
    workspace_path: str
        A path of the workspace
    repo_path: str
        A path of the repository
    storage_path: str
        A path of the storage
    shared_volume_path: str
        A path of the shared volume

    Methods
    -------
    run_docker_containers()
        Run storage target container and proxy container
    run_vm_instance_on_proxy_container_platform()
        Run VM on a proxy container
    """

    def __init__(self):

        self.proxy_terminal = ExtendedTerminal(address=ip_address_proxy, user=user_name, password=password)
        self.storage_terminal = ExtendedTerminal(address=ip_address_storage, user=user_name, password=password)
        self.cmd_sender_terminal = ExtendedTerminal(address=ip_address_cmd_sender, user=user_name, password=password)

        self.workspace_path = WORKSPACE_PATH
        self.repo_path = os.path.join(self.workspace_path, "ipdk")
        self.storage_path = os.path.join(
            self.workspace_path,
            "ipdk/build/storage",
        )
        self.shared_volume_path = os.path.join(self.workspace_path, "SHARE")

    def run_docker_containers(self) -> List[int]:
        """
        Run storage target container and proxy container

        Returns
        -------
        tuple(int, int)
            A tuple of return codes from running containers
        """

        self.proxy_terminal.mkdir(path=self.shared_volume_path)
        return_codes = []
        _, rc = self.storage_terminal.execute_as_root(cwd=self.storage_path,
                                                      cmd="AS_DAEMON=true scripts/run_storage_target_container.sh")
        return_codes.append(rc)
        _, rc = self.proxy_terminal.execute_as_root(cwd=self.storage_path,
                                                    cmd=f"AS_DAEMON=true SHARED_VOLUME={self.shared_volume_path} "
                                                        f"scripts/run_ipu_storage_container.sh",)
        return_codes.append(rc)
        return return_codes

    def run_docker_from_image(self, image):
        out, rc = self.cmd_sender_terminal.execute_as_root(f'docker run --mount type=bind,source="{WORKSPACE_PATH}",'
                                                           f'target=/workspace -d -it --privileged --network host '
                                                           f'--entrypoint /bin/bash {image}')
        out = out.strip()
        logging.info(f"Docker started with id: {out}")
        return rc

    def run_vm_instance_on_proxy_container_platform(self):
        """Run VM on a proxy container"""

        self.proxy_terminal.execute_as_root(
            cmd=f"cd {self.storage_path} && SHARED_VOLUME={self.shared_volume_path} "
            f"./scripts/vm/run_vm.sh"
        )

    def run_tests(self) -> bool:
        """Run tests on a proxy container and build docker images"""

        _, rc = self.proxy_terminal.execute_as_root(
            cmd="tests/it/run.sh", cwd=self.storage_path
        )
        return not rc
