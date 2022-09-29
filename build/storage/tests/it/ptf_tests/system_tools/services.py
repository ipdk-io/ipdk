# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import os


class TestStep:
    def __init__(self, terminal, is_teardown=False):
        self.terminal = terminal
        self.is_teardown = is_teardown

    def _prepare(self):
        pass

    def _assertions_before_step(self):
        pass

    def _step(self):
        pass

    def _teardown(self):
        pass

    def _assertion_after_step(self):
        pass

    def run(self):
        self._prepare()
        self._assertions_before_step()
        self._step()
        self._assertion_after_step()
        if self.is_teardown:
            self._teardown()


class CloneIPDKRepository(TestStep):

    def __init__(self, terminal, is_teardown, repository_url, branch='main', workdir=None):
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
        cmd = f'cd {self.workdir} && git clone --branch {self.branch} {self.repository_url}'
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        self.terminal.execute(f"cd {self.workdir}/ipdk/build")
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

    def __init__(self, terminal, storage_dir, is_teardown=False):
        super().__init__(terminal, is_teardown)
        self.storage_dir = storage_dir

    def _step(self):
        cmd = f'cd {self.storage_dir} && ' \
              f'AS_DAEMON=true scripts/run_storage_target_container.sh'
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "storage-target" in line:
                is_container = True
        assert is_container


class RunIPUStorageContainer(TestStep):

    def __init__(self, terminal, storage_dir, shared_dir, is_teardown=False):
        super().__init__(terminal, is_teardown)
        self.storage_dir = storage_dir
        self.shared_dir = shared_dir

    def _prepare(self):
        self.terminal.client.exec_command(f'mkdir -p {self.shared_dir}')

    def _step(self):
        cmd = f"cd {self.storage_dir} && " \
              f"AS_DAEMON=true SHARED_VOLUME={self.shared_dir} "\
              f"scripts/run_ipu_storage_container.sh"
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "ipu-storage-container" in line:
                is_container = True
        assert is_container


class RunHostRargetContainer(TestStep):

    def __init__(self, terminal, storage_dir, is_teardown=False):
        super().__init__(terminal, is_teardown)
        self.storage_dir = storage_dir

    def _step(self):
        cmd = f"cd {self.storage_dir} && " \
              f"AS_DAEMON=true scripts/run_host_target_container.sh"
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "host-target" in line:
                is_container = True
        assert is_container
