#!/bin/bash
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

SCRIPT_PATH=$(realpath $(dirname $BASH_SOURCE))
PTF_TESTS_PATH=$(dirname $SCRIPT_PATH)
TESTS_PATH=$PTF_TESTS_PATH/tests
source $PTF_TESTS_PATH/venv/bin/activate
sudo env PATH=$PATH PYTHONPATH=$PTF_TESTS_PATH ptf --test-dir $TESTS_PATH --platform=dummy
