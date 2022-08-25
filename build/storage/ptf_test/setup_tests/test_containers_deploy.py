import json
import sys
from pathlib import Path

sys.path.append('../')

from python_system_tools.extendedterminal import ExtendedTerminal
from python_system_tools.containers_deploy import ContainersDeploy
from ptf import testutils
from ptf.base_tests import BaseTest
from python_system_tools.data import cmd_docker_name


class TestRunDockersContainers(BaseTest):

    def setUp(self):
        self.containers_deploy = ContainersDeploy()

    def runTest(self):
        assert self.containers_deploy.run_docker_containers() == [0, 0]
        assert self.containers_deploy.run_docker_from_image(image=cmd_docker_name) == 0

    def tearDown(self):
        pass
