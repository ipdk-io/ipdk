#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

[ "$DEBUG" == 'true' ] && set -x

export IMAGE_NAME="cmd-sender"
scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# shellcheck source=./scripts/run_container.sh
# shellcheck disable=SC1091,SC1090
source "${scripts_dir}/run_container.sh"
