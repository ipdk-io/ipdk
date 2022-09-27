#!/bin/bash
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

SCRIPT_PATH=$(realpath $(dirname $BASH_SOURCE))
PTF_TESTS_PATH=$(dirname $SCRIPT_PATH)
cd $PTF_TESTS_PATH

#create python environment
sudo apt-install -y python3.10 || sudo dnf -y install python3.10
python3.10 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
