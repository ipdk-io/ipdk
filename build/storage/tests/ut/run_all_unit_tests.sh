#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

if [ "$DEBUG" == 'true' ]; then
    set -x
fi
export GRPC_VERBOSITY=NONE

result=0
python -m unittest discover -v -s /host-target/tests
result=$(("$?" | "${result}"))

exit "${result}"
