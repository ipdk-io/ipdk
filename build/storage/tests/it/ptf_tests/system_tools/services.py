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
        _, stdout, stderr = self.terminal.client.exec_command(f"cd {self.workdir}")
        assert not stderr.read().decode()
        _, stdout, stderr = self.terminal.client.exec_command(f"cd {self.workdir}/ipdk/build/storage")
        assert not stderr.read().decode()
        _, stdout, stderr = self.terminal.client.exec_command(f"cd {self.workdir}/ipdk/build/storage && git log")
        assert not stderr.read().decode()


class RunDockerStorageContainer(TestStep):
    pass


class RunDockerIpuStorageContainer(TestStep):
    pass


class RunVmInstance(TestStep):
    pass


class RunSender(TestStep):
    pass


class RunStorageTargetContainer(TestStep):

    def __init__(self, terminal, is_teardown=False, storage_dir=None):
        super().__init__(terminal, is_teardown)
        self.terminal = terminal
        self.storage_dir = storage_dir

    def _step(self):
        cmd = f'cd {self.storage_dir} && ' \
              f'AS_DAEMON=true scripts/run_storage_target_container.sh'
        _, self.stdout, _ = self.terminal.client.exec_command(cmd)

    def _assertion_after_step(self):
        assert not self.stdout.channel.recv_exit_status()

        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "storage-target" in line:
                is_container = True
        assert is_container


class RunIPUStorageContainer(TestStep):

    def __init__(self, terminal, is_teardown=False, storage_dir=None, shared_dir=None):
        super().__init__(terminal, is_teardown)
        self.terminal = terminal
        self.storage_dir = storage_dir
        self.shared_dir = shared_dir or f'/home/{terminal.config.username}/share'

    def _prepare(self):
        self.terminal.client.exec_command(f'mkdir -p {self.shared_dir}')

    def _assertion_after_step(self):
        out = self.terminal.execute('docker ps -aq')
        assert not out

    def _step(self):
        cmd = f"cd {self.storage_dir} && " \
              f"AS_DAEMON=true SHARED_VOLUME={self.shared_dir} "\
              f"scripts/run_ipu_storage_container.sh"
        _, self.stdout, _ = self.terminal.client.exec_command(cmd)

    def _assertion_after_step(self):
        assert not self.stdout.channel.recv_exit_status()

        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "ipu-storage-container" in line:
                is_container = True
        assert is_container


class RunHostRargetContainer(TestStep):

    def __init__(self, terminal, is_teardown=False, storage_dir=None):
        super().__init__(terminal, is_teardown)
        self.terminal = terminal
        self.storage_dir = storage_dir

    def _step(self):
        cmd = f"cd {self.storage_dir} && " \
              f"AS_DAEMON=true scripts/run_host_target_container.sh"
        _, self.stdout, _ = self.terminal.client.exec_command(cmd)

    def _assertion_after_step(self):
        assert not self.stdout.channel.recv_exit_status()

        out = self.terminal.execute("docker ps")
        is_container = False
        for line in out:
            if "host-target" in line:
                is_container = True
        assert is_container
