#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import logging
import argparse

from hot_plug_grpc_server import run_grpc_server
from hot_plug_provider import HotPlugProvider


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Runs service for hot-plug/hot-detach virtio-blk devices to vms"
    )
    parser.add_argument("--ip", required=True, help="ip address the server listens to")
    parser.add_argument(
        "--port", type=int, default=50051, help="port number the server listens to"
    )
    parser.add_argument(
        "--shared-dir",
        type=str,
        required=True,
        help="Directory path to shared with Host resources",
    )
    parser.add_argument(
        "--host-shared-dir",
        type=str,
        required=True,
        help="Directory path to shared with container resources",
    )

    args = parser.parse_args()
    return args


if __name__ == "__main__":
    logging.basicConfig()

    args = parse_arguments()

    ip_address = args.ip
    port = args.port
    hot_plug_provider = HotPlugProvider(args.shared_dir, args.host_shared_dir)
    run_grpc_server(ip_address, port, hot_plug_provider)
