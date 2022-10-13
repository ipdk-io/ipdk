#!/bin/bash
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

SCRIPT_PATH=$(realpath "$(dirname -- "${BASH_SOURCE[0]}")")
PTF_TESTS_PATH=$(dirname "$SCRIPT_PATH")
cd -- "$PTF_TESTS_PATH" || exit 1

# create python environment
sudo apt-install -y python3 || sudo dnf -y install python3
python3 -m venv venv
# shellcheck disable=SC1091,SC1090
source venv/bin/activate
pip install -r requirements.txt
