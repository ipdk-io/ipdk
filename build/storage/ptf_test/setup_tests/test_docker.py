import json
import sys
from pathlib import Path

sys.path.append('../')

from python_system_tools.extendedterminal import ExtendedTerminal
from python_system_tools.docker import Docker
from ptf import testutils
from ptf.base_tests import BaseTest
from python_system_tools.data import ip_address_proxy, ip_address_storage, ip_address_cmd_sender, user_name, password, \
    storage_docker_image, proxy_docker_image, cmd_docker_name



class TestImages(BaseTest):

    def setUp(self):
        self.proxy_terminal = ExtendedTerminal(address=ip_address_proxy, user=user_name, password=password)

    def runTest(self):
        images = ("test-driver", "traffic-generator", "spdk-app")
        out, _ = self.proxy_terminal.execute("docker images")
        for image in images:
            assert image in out

    def tearDown(self):
        pass


class TestGetDockerID(BaseTest):

    def setUp(self):
        self.docker_proxy = Docker(address=ip_address_proxy, user=user_name, password=password)
        self.docker_storage = Docker(address=ip_address_storage, user=user_name, password=password)

    def runTest(self):
        assert self.docker_storage.get_docker_id(storage_docker_image) is not None
        assert self.docker_proxy.get_docker_id(proxy_docker_image) is not None

    def tearDown(self):
        pass


class TestExecuteInDocker(BaseTest):

    def setUp(self):
        self.docker_proxy = Docker(address=ip_address_proxy, user=user_name, password=password)
        self.docker_storage = Docker(address=ip_address_storage, user=user_name, password=password)

    def runTest(self):
        storage_container_id = self.docker_storage.get_docker_id(storage_docker_image)
        proxy_container_id = self.docker_proxy.get_docker_id(proxy_docker_image)

        cmd = "echo Hello, World!"

        out, rc = self.docker_storage.execute_in_docker(cmd, storage_container_id, user_name)
        assert out, rc == ("Hello, World!\n", 0)

        out, rc = self.docker_proxy.execute_in_docker(cmd, proxy_container_id, user_name)
        assert out, rc == ("Hello, World!\n", 0)

    def tearDown(self):
        self.docker_proxy.kill_container(
            container_id=self.docker_proxy.get_docker_id(docker_image=proxy_docker_image))
        self.docker_storage.kill_container(
            container_id=self.docker_storage.get_docker_id(docker_image=storage_docker_image))
        docker_cmd = Docker(address=ip_address_cmd_sender, user=user_name, password=password)
        docker_cmd.kill_container(
            container_id=docker_cmd.get_docker_id(docker_image=cmd_docker_name))


