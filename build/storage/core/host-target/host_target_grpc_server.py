#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from concurrent import futures

import grpc
from grpc_reflection.v1alpha import reflection
import host_target_pb2
import host_target_pb2_grpc
from device_exerciser import DeviceExerciser
from fio_runner import run_fio
from pci_devices import get_virtio_blk_path_by_pci_address


class InvalidHotPlugProvider(RuntimeError):
    def __init__(self, message):
        super().__init__(message)


class HostTargetService(host_target_pb2_grpc.HostTargetServicer):
    def __init__(self, fio_runner, virtio_blk_detector):
        super().__init__()
        self.device_exerciser = DeviceExerciser(fio_runner, virtio_blk_detector)

    def RunFio(self, request, context):
        output = None
        try:
            output = self.device_exerciser.run_fio(request.pciAddress, request.fioArgs)
        except BaseException as ex:
            context.set_code(grpc.StatusCode.FAILED_PRECONDITION)
            context.set_details(str(ex))
        return host_target_pb2.RunFioReply(fioOutput=output)


def run_grpc_server(ip_address, port, server_creator=grpc.server):
    try:
        server = server_creator(futures.ThreadPoolExecutor(max_workers=10))
        host_target_pb2_grpc.add_HostTargetServicer_to_server(
            HostTargetService(run_fio, get_virtio_blk_path_by_pci_address), server
        )
        service_names = (
            host_target_pb2.DESCRIPTOR.services_by_name["HostTarget"].full_name,
            reflection.SERVICE_NAME,
        )
        reflection.enable_server_reflection(service_names, server)
        server.add_insecure_port(ip_address + ":" + str(port))
        server.start()
        server.wait_for_termination()
        return 0
    except KeyboardInterrupt as ex:
        return 0
    except BaseException as ex:
        print("Couldn't run gRPC server. Error: " + str(ex))
        return 1
