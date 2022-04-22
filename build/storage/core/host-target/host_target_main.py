#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import logging
import argparse

from host_target_grpc_server import run_grpc_server


def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Runs service for hot-plug/hot-detach virtio-blk devices to vms')
    parser.add_argument('--ip', required=True,
                        help='ip address the server listens to')
    parser.add_argument('--port', type=int, default=50051,
                        help='port number the server listens to')

    args = parser.parse_args()
    return args


if __name__ == '__main__':
    logging.basicConfig()

    args = parse_arguments()

    run_grpc_server(args.ip, args.port)
