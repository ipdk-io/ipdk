# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

class TestStory:
    def __init__(self):
        steps = []

    def _prepare_environment(self):
        pass

    def _clean(self):
        pass

    def run(self):
        self._prepare_environment()
        for step in self.steps:
            step.run()
        self._clean()


class TestStep:
    def __init__(self):
        pass

    def _before(self):
        pass

    def _step(self):
        pass

    def _after(self):
        pass

    def run(self):
        self._before()
        self._step()
        self._after()
