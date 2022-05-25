#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from concurrent import futures

import grpc
from grpc_reflection.v1alpha import reflection
import hot_plug_pb2
import hot_plug_pb2_grpc


class InvalidHotPlugProvider(RuntimeError):
    def __init__(self, message):
        super().__init__(message)


class HotPlugService(hot_plug_pb2_grpc.HotPlugServicer):
    def __init__(self, hot_plug_provider):
        super().__init__()
        if hot_plug_provider == None:
            raise InvalidHotPlugProvider("HotPlugProvider cannot be None")
        self.hot_plug_provider = hot_plug_provider

    def __execute_server_operation(self, request, context, operation):
        try:
            operation(request.vmId, request.vhostVirtioBlkId)
        except BaseException as ex:
            context.set_code(grpc.StatusCode.FAILED_PRECONDITION)
            context.set_details(str(ex))
        return hot_plug_pb2.HotPlugReply()

    def HotPlugVirtioBlk(self, request, context):
        return self.__execute_server_operation(
            request, context, self.hot_plug_provider.hot_plug_vhost_virtio_blk
        )

    def HotUnplugVirtioBlk(self, request, context):
        return self.__execute_server_operation(
            request, context, self.hot_plug_provider.hot_unplug_vhost_virtio_blk
        )


def run_grpc_server(ip_address, port, hot_plug_provider):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    hot_plug_pb2_grpc.add_HotPlugServicer_to_server(
        HotPlugService(hot_plug_provider), server
    )
    service_names = (
        hot_plug_pb2.DESCRIPTOR.services_by_name["HotPlug"].full_name,
        reflection.SERVICE_NAME,
    )
    reflection.enable_server_reflection(service_names, server)
    server.add_insecure_port(ip_address + ":" + str(port))
    server.start()
    server.wait_for_termination()
