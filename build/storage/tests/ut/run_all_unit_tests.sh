#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

if [ "$DEBUG" == 'true' ]; then
    set -x
    export GRPC_VERBOSITY=ERROR
else
    export GRPC_VERBOSITY=NONE
fi
ls -l /host-target/tests

result=0
python -m unittest discover -v -s /proxy-container/tests
result=$(("$?" | "${result}"))
python -m unittest discover -v -s /host-target/tests
result=$(("$?" | "${result}"))

exit "${result}"
