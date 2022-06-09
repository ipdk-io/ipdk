#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

export DEFAULT_QMP_PORT=5555
export DEFAULT_QMP_ADDRESS="0.0.0.0"
export IPDK_PCI_BRIDGE_0="pci.ipdk.0"
export IPDK_PCI_BRIDGE_1="pci.ipdk.1"
