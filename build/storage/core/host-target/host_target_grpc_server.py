#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import grpc
import logging
import host_target_pb2
import host_target_pb2_grpc
from concurrent import futures
from grpc_reflection.v1alpha import reflection
from device_exerciser_kvm import DeviceExerciserKvm
from device_exerciser_if import *


class HostTargetService(host_target_pb2_grpc.HostTargetServicer):
    def __init__(
        self,
        device_exerciser,
    ):
        super().__init__()
        self._device_exerciser = device_exerciser

    def RunFio(self, request, context):
        logging.debug(f"RunFio: request:'{request}'")
        output = None
        try:
            output = self._device_exerciser.run_fio(
                request.deviceHandle, request.fioArgs
            )
        except BaseException as ex:
            logging.error("Service exception: '" + str(ex) + "'")
            context.set_code(grpc.StatusCode.FAILED_PRECONDITION)
            context.set_details(str(ex))
        return host_target_pb2.RunFioReply(fioOutput=output)


def default_device_exerciser_factory() -> DeviceExerciserIf:
    return DeviceExerciserKvm()


def run_grpc_server(ip_address, port, server_creator=grpc.server):
    try:
        server = server_creator(futures.ThreadPoolExecutor(max_workers=10))
        host_target_pb2_grpc.add_HostTargetServicer_to_server(
            HostTargetService(default_device_exerciser_factory()), server
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
        logging.error("Couldn't run gRPC server. Error: " + str(ex))
        return 1
