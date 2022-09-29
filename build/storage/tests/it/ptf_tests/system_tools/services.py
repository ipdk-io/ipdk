# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
from system_tools.ssh_terminal import SSHTerminal


class TestStep:
    """The base class represents the single step in test story
    It's abstract class
    """

    def __init__(self, terminal: SSHTerminal, is_teardown: bool = False) -> None:
        self.terminal = terminal
        self.is_teardown = is_teardown

    def _prepare(self):
        pass

    def _assertions_before_step(self):
        pass

    def _step(self):
        pass

    def _assertion_after_step(self):
        pass

    def _teardown(self):
        pass

    def run(self):
        """This is the only public method in step

        This method represents what you have to do if you want properly validate one step in test story.
        First, you have to prepare environment. Second, check if all preconditions are fulfilled.
        Next is action and check if postconditions is fulfilled. The last is bringing environment to beggining.

        If you initialize class with is_teardown=False the environment after step not will be bringing to beggining.
        It is allow connect steps with whole test story.
        You have to remember to yourself teardown environment after all steps.
        """
        self._prepare()
        self._assertions_before_step()
        self._step()
        self._assertion_after_step()
        if self.is_teardown:
            self._teardown()


class CloneIPDKRepository(TestStep):
    """Clone ipdk repository"""

    def __init__(
        self,
        terminal: SSHTerminal,
        is_teardown: bool,
        repository_url: str,
        branch: str = "main",
        workdir: str = None,
    ) -> None:
        """
        Assumption: In workdir folder You can't have any important files
        All files will be deleted
        """
        super().__init__(terminal, is_teardown)
        self.repository_url = repository_url
        self.branch = branch
        self.workdir = workdir or f"/home/{terminal.config.username}/ipdk_tests_workdir"

    def _prepare(self):
        self.terminal.execute(f"sudo rm -rf {self.workdir}")
        self.terminal.execute(f"mkdir {self.workdir}")

    # TODO: init submodules
    def _step(self):
        cmd = f"cd {self.workdir} && git clone --branch {self.branch} {self.repository_url}"
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        self.terminal.execute(f"ls {self.workdir}/ipdk/build")
        self.terminal.execute(f"cd {self.workdir}/ipdk/build/storage && git log")


class RunDockerStorageContainer(TestStep):
    pass


class RunDockerIpuStorageContainer(TestStep):
    pass


class RunVmInstance(TestStep):
    pass


class RunSender(TestStep):
    pass


class RunStorageTargetContainer(TestStep):
    def __init__(
        self, terminal: SSHTerminal, storage_dir: str, is_teardown: bool = False
    ) -> None:
        super().__init__(terminal, is_teardown)
        self.storage_dir = storage_dir

    def _step(self):
        cmd = (
            f"cd {self.storage_dir} && "
            f"AS_DAEMON=true scripts/run_storage_target_container.sh"
        )
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "storage-target" in line:
                is_container = True
        assert is_container


class RunIPUStorageContainer(TestStep):
    def __init__(
        self,
        terminal: SSHTerminal,
        storage_dir: str,
        shared_dir: str,
        is_teardown: bool = False,
    ) -> None:
        super().__init__(terminal, is_teardown)
        self.storage_dir = storage_dir
        self.shared_dir = shared_dir

    def _prepare(self):
        self.terminal.client.exec_command(f"mkdir -p {self.shared_dir}")

    def _step(self):
        cmd = (
            f"cd {self.storage_dir} && "
            f"AS_DAEMON=true SHARED_VOLUME={self.shared_dir} "
            f"scripts/run_ipu_storage_container.sh"
        )
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "ipu-storage-container" in line:
                is_container = True
        assert is_container


class RunHostTargetContainer(TestStep):
    def __init__(
        self, terminal: SSHTerminal, storage_dir: str, is_teardown: bool = False
    ) -> None:
        super().__init__(terminal, is_teardown)
        self.storage_dir = storage_dir

    def _step(self):
        cmd = (
            f"cd {self.storage_dir} && "
            f"AS_DAEMON=true scripts/run_host_target_container.sh"
        )
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        # it's ok but container stops after few seconds
        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "host-target" in line:
                is_container = True
        assert is_container
