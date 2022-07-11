#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import logging
import argparse
import sys
import os

from host_target_grpc_server import run_grpc_server


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Service to run fio traffic over disks."
    )
    parser.add_argument("--ip", required=True, help="ip address the server listens to")
    parser.add_argument(
        "--port", type=int, default=50051, help="port number the server listens to"
    )

    args = parser.parse_args()
    return args


if __name__ == "__main__":
    logging.basicConfig(level=os.environ.get("HOST_TARGET_LOGLEVEL", "WARNING").upper())

    args = parse_arguments()

    sys.exit(run_grpc_server(args.ip, args.port))
