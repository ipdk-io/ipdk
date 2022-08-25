import json
import sys
from pathlib import Path

sys.path.append('../')

from python_system_tools.extendedterminal import ExtendedTerminal
from python_system_tools.containers_deploy import ContainersDeploy
from ptf import testutils
from ptf.base_tests import BaseTest
from python_system_tools.data import ip_address_proxy, ip_address_storage, ip_address_cmd_sender, user_name, password


class TestExecute(BaseTest):

    def setUp(self):
        self.proxy_terminal = ExtendedTerminal(address=ip_address_proxy, user=user_name, password=password, )
        self.storage_terminal = ExtendedTerminal(address=ip_address_storage, user=user_name, password=password)
        self.cmd_sender_terminal = ExtendedTerminal(address=ip_address_cmd_sender, user=user_name, password=password)
        self.terminals = [self.proxy_terminal, self.storage_terminal, self.cmd_sender_terminal]

    def runTest(self):
        for terminal in self.terminals:
            assert terminal.execute("whoami") == (f"{user_name}\n", 0)

    def tearDown(self):
        pass


class TestExecuteAsRoot(BaseTest):

    def setUp(self):
        self.proxy_terminal = ExtendedTerminal(address=ip_address_proxy, user=user_name, password=password)
        self.storage_terminal = ExtendedTerminal(address=ip_address_storage, user=user_name, password=password)
        self.cmd_sender_terminal = ExtendedTerminal(address=ip_address_cmd_sender, user=user_name, password=password)
        self.terminals = [self.proxy_terminal, self.storage_terminal, self.cmd_sender_terminal]

    def runTest(self):
        for terminal in self.terminals:
            assert terminal.execute_as_root("whoami") == (f"root\n", 0)

    def tearDown(self):
        pass

class TestMkdir(BaseTest):

    def setUp(self):
        self.proxy_terminal = ExtendedTerminal(address=ip_address_proxy, user=user_name, password=password, )
        self.storage_terminal = ExtendedTerminal(address=ip_address_storage, user=user_name, password=password)
        self.cmd_sender_terminal = ExtendedTerminal(address=ip_address_cmd_sender, user=user_name, password=password)
        self.terminals = [self.proxy_terminal, self.storage_terminal, self.cmd_sender_terminal]

    def runTest(self):
        path = "~/empty_test_folder"

        for terminal in self.terminals:
            terminal.mkdir(path)
            out, _ = terminal.execute("ls ~/")
            assert "empty_test_folder" in out
            assert terminal.execute("rmdir ~/empty_test_folder")[1] == 0

    def tearDown(self):
        pass
