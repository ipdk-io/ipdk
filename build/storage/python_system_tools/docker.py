import logging
import re
import sys
from typing import Optional, Tuple

sys.path.append('../')


from python_system_tools.extendedterminal import ExtendedTerminal


class DockerException(Exception):
    """A custom Exception of a Docker class"""


class Docker(ExtendedTerminal):
    """
    A subclass of ExtendedTerminal used to represent Docker specific operations

    ...

    Attributes
    ----------
    container_ids: set
        A set of container ids

    Methods
    -------
    execute_in_docker(cmd, container_id, raise_on_error=True)
        Executes a command in docker container with a given id,
        raises error when command execution fails and raise_on_error is set to True (default True)
    get_docker_id(docker_image)
        Checks a container id based on the docker image
    kill_container(container_id)
        Kills a container with a given id
    kill_all_containers()
        Kills all containers
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

        super().__init__(address, user, password)
        self.container_ids = set()

    def execute_in_docker(
        self, cmd: str, container_id: str, raise_on_error=True
    ) -> Tuple[str, int]:
        """
        Executes a command in docker container with a given id

        Parameters
        ----------
        cmd: str
            The command to execute
        container_id: str
            A container id
        raise_on_error: bool
            Specify if error is raised when the command execution fails (default True)

        Returns
        -------
        tuple(str, int)
            The tuple of the output and return code of the executed command

        Raises
        ------
        ExtendedTerminalException
            When command execution fails and raise_on_error is set to True (default True)
        """

        logging.info(f"Execute command {cmd}\non docker {container_id}")
        return self.execute(
            f'docker exec {container_id} sh -c "{cmd}"', raise_on_error=raise_on_error
        )

    def get_docker_id(self, docker_image: str) -> Optional[str]:
        """
        Checks a container id based on the docker image

        Parameters
        ----------
        docker_image: str
            A docker image

        Returns
        -------
        str | None
            A container id or None if there is no match
        """

        out, _ = self.execute("docker ps")
        regex = re.compile(rf"(?<=\n)\w{{12}}(?=\s+{docker_image})")
        return regex.search(out).group()

    def kill_container(self, container_id: str) -> Tuple[str, int]:
        """
        Kills a container with a given id

        Parameters
        ----------
        container_id: str
            A container id

        Returns
        -------
        tuple(str, int)
            The tuple of the output and return code of the executed command
        """

        logging.info(f"Kill docker container {container_id}")
        return self.execute(f"docker kill {container_id}")

    def kill_all_containers(self) -> None:
        """Kills all containers"""

        left_alive_containers = set()
        for container_id in self.container_ids:
            out, rc = self.kill_container(container_id)
            if rc:
                logging.warning(
                    f"Cannot kill docker container: {container_id}. An attempt to kill it resulted in rc: "
                    f"{rc}\n output: {out}"
                )
                left_alive_containers.add(container_id)
        self.container_ids = left_alive_containers