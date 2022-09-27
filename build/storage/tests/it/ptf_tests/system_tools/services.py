# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#


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


class CloneRepository(TestStep):

    def __init__(self, terminal, is_teardown, repository_url, branch='master', workdir=None):
        super().__init__(terminal, is_teardown)
        self.terminal = terminal
        self.workdir = workdir or f"/home/{terminal.config.username}/workdir"
        self.repository_url = repository_url
        self.branch = branch

    def _prepare(self):
        self.terminal.execute(f"sudo rm -rf {self.workdir}")
        self.terminal.execute(f"mkdir {self.workdir}")

    def _step(self):
        cmd = f'cd {self.workdir} && git clone --branch {self.branch} {self.repository_url}'
        self.terminal.execute(cmd)

    def _assertion_after_step(self):
        _, stdout, stderr = self.terminal.terminal.exec_command(f"cd {self.workdir}")
        assert not stderr.read().decode()
        _, stdout, stderr = self.terminal.terminal.exec_command(f"cd {self.workdir}/ipdk/build/storage")
        assert not stderr.read().decode()
        _, stdout, stderr = self.terminal.terminal.exec_command(f"cd {self.workdir}/ipdk/build/storage && git log")
        assert not stderr.read().decode()


class RunDockerStorageContainer(TestStep):
    pass


class RunDockerIpuStorageContainer(TestStep):
    pass


class RunVmInstance(TestStep):
    pass


class RunSender(TestStep):
    pass
