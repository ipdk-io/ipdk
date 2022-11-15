#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import base64
import importlib
import logging
import os
import re
import socket
import sys
import time
import uuid

from scripts import socket_functions

sys.path.append("/usr/libexec/spdk/scripts")
sma_client = importlib.import_module("sma-client")
import rpc

logging.root.setLevel(logging.CRITICAL)


def get_number_of_virtio_blk(sock: str) -> int:
    return _get_number_of_devices(sock, "vd[a-z]+\\b")


def get_number_of_nvme_devices(sock: str) -> int:
    return _get_number_of_devices(sock, "nvme[0-9]+\\b")


def get_number_of_nvme_namespaces(sock: str) -> int:
    return _get_number_of_devices(sock, "nvme[0-9]+n[0-9]+\\b")


def _get_number_of_devices(sock: str, device_regex_filter: str) -> int:
    cmd = "ls -1 /dev"
    out = socket_functions.send_command_over_unix_socket(
        sock=sock, cmd=cmd, wait_for_secs=1
    )
    logging.info(out)
    number_of_devices = len(re.findall(device_regex_filter, out))
    return number_of_devices


def is_virtio_blk_attached(sock: str) -> bool:
    if get_number_of_virtio_blk(sock) == 0:
        logging.error("virtio-blk is not found")
        return False
    logging.info("virtio-blk is found")
    return True


def _verify_expected_number_of_devices(
    expected_number_of_devices: int, number_of_devices: int
) -> bool:
    if number_of_devices != expected_number_of_devices:
        logging.error(
            f"Required number of devices '{expected_number_of_devices}' does "
            f"not equal to actual number of devices '{number_of_devices}'"
        )
        return False
    else:
        logging.info(f"Number of attached virtio-blk devices is '{number_of_devices}'")
        return True


def verify_expected_number_of_virtio_blk_devices(
    vm_serial: str, expected_number_of_devices: int
) -> bool:
    number_of_devices = get_number_of_virtio_blk(vm_serial)
    return _verify_expected_number_of_devices(
        expected_number_of_devices, number_of_devices
    )


def verify_expected_number_of_nvme_devices(
    vm_serial: str, expected_number_of_devices: int
) -> bool:
    number_of_devices = get_number_of_nvme_devices(vm_serial)
    return _verify_expected_number_of_devices(
        expected_number_of_devices, number_of_devices
    )


def verify_expected_number_of_nvme_namespaces(
    vm_serial: str, expected_number_of_namespaces: int
) -> bool:
    number_of_devices = get_number_of_nvme_namespaces(vm_serial)
    return _verify_expected_number_of_devices(
        expected_number_of_namespaces, number_of_devices
    )


def create_and_expose_subsystem_over_tcp(
    ip_addr: str, nqn: str, port_to_expose: str, storage_target_port: int
) -> None:
    requests = [
        {
            "method": "nvmf_create_subsystem",
            "params": {
                "nqn": nqn,
                "serial_number": "SPDK00000000000001",
                "allow_any_host": True,
                "max_namespaces": 1024,
            },
        },
        {
            "method": "nvmf_create_transport",
            "params": {"trtype": "TCP", "io_unit_size": 8192},
        },
        {
            "method": "nvmf_subsystem_add_listener",
            "params": {
                "nqn": nqn,
                "listen_address": {
                    "trtype": "TCP",
                    "adrfam": "IPv4",
                    "traddr": ip_addr,
                    "trsvcid": port_to_expose,
                },
            },
        },
    ]
    send_requests(
        requests=requests,
        function=send_rpc_request,
        addr=ip_addr,
        port=storage_target_port,
    )


def create_ramdrive_and_attach_as_ns_to_subsystem(
    ip_addr: str,
    ramdrive_name: str,
    ramdrive_size_in_mb: int,
    nqn: str,
    storage_target_port: int,
) -> str:
    requests = [
        {
            "method": "bdev_malloc_create",
            "params": {
                "name": ramdrive_name,
                "num_blocks": ramdrive_size_in_mb * 256,
                "block_size": 4096,
            },
        },
        {
            "method": "nvmf_subsystem_add_ns",
            "params": {"nqn": nqn, "namespace": {"bdev_name": ramdrive_name}},
        },
        {"method": "bdev_get_bdevs", "params": {"name": ramdrive_name}},
    ]
    response = send_requests(
        requests=requests,
        function=send_rpc_request,
        addr=ip_addr,
        port=storage_target_port,
    )
    device_uuid = response[2][0]["uuid"]
    return device_uuid


def uuid2base64(device_uuid: str) -> str:
    return base64.b64encode(uuid.UUID(device_uuid).bytes).decode()


def create_virtio_blk(
    ipu_storage_container_ip: str,
    sma_port: int,
    host_target_ip: str,
    host_target_service_port: int,
    volume_id: str,
    physical_id: str,
    virtual_id: str,
    hostnqn: str,
    traddr: str,
    trsvcid: str,
) -> str:
    request = {
        "method": "CreateDevice",
        "params": {
            "volume": {
                "volume_id": uuid2base64(volume_id),
                "nvmf": {
                    "hostnqn": hostnqn,
                    "discovery": {
                        "discovery_endpoints": [
                            {"trtype": "tcp", "traddr": traddr, "trsvcid": trsvcid}
                        ]
                    },
                },
            },
            "virtio_blk": {"physical_id": physical_id, "virtual_id": virtual_id},
        },
    }
    response = send_sma_request(
        request=request,
        addr=ipu_storage_container_ip,
        port=sma_port,
    )
    device_handle = response["handle"]

    if device_handle:
        if (
            os.system(
                f'env -i no_grpc_proxy="" grpc_cli call \
            "{host_target_ip}:{host_target_service_port}" \
            PlugDevice "deviceHandle: \'{device_handle}\'"'
            )
            == 0
        ):
            return device_handle
        else:
            _send_delete_sma_device_request(
                ipu_storage_container_ip, sma_port, device_handle
            )

    return ""


def _send_delete_sma_device_request(ipu_storage_container_ip, sma_port, device_handle):
    request = {"method": "DeleteDevice", "params": {"handle": device_handle}}
    send_sma_request(request, ipu_storage_container_ip, sma_port)


def delete_sma_device(
    ipu_storage_container_ip: str,
    sma_port: int,
    host_target_ip: str,
    host_target_service_port: int,
    device_handle: str,
) -> bool:
    try:
        if (
            os.system(
                f'env -i no_grpc_proxy="" grpc_cli call \
                "{host_target_ip}:{host_target_service_port}" \
                UnplugDevice "deviceHandle: \'{device_handle}\'"'
            )
            == 0
        ):
            _send_delete_sma_device_request(
                ipu_storage_container_ip, sma_port, device_handle
            )
            return True
    except Exception as ex:
        logging.error(ex)

    return False


def wait_for_volume_in_os(timeout: float = 2.0) -> None:
    time.sleep(timeout)


def create_nvme_device(
    ipu_storage_container_ip: str,
    sma_port: int,
    host_target_ip: str,
    host_target_service_port: int,
    physical_id: str,
    virtual_id: str,
) -> str:
    request = {
        "method": "CreateDevice",
        "params": {
            "nvme": {"physical_id": physical_id, "virtual_id": virtual_id},
        },
    }
    response = send_sma_request(
        request=request,
        addr=ipu_storage_container_ip,
        port=sma_port,
    )
    device_handle = response["handle"]
    if device_handle:
        if (
            os.system(
                f'env -i no_grpc_proxy="" grpc_cli call \
            "{host_target_ip}:{host_target_service_port}" \
            PlugDevice "deviceHandle: \'{device_handle}\'"'
            )
            == 0
        ):
            return device_handle
        else:
            _send_delete_sma_device_request(
                ipu_storage_container_ip, sma_port, device_handle
            )

    return ""


def attach_volume(
    ipu_storage_container_ip: str,
    sma_port: int,
    device_handle: str,
    volume_id: str,
    nqn: str,
    traddr: str,
    trsvcid: str,
) -> None:
    request = {
        "method": "AttachVolume",
        "params": {
            "device_handle": device_handle,
            "volume": {
                "volume_id": uuid2base64(volume_id),
                "nvmf": {
                    "hostnqn": nqn,
                    "discovery": {
                        "discovery_endpoints": [
                            {"trtype": "tcp", "traddr": traddr, "trsvcid": trsvcid}
                        ]
                    },
                },
            },
        },
    }
    send_sma_request(request=request, addr=ipu_storage_container_ip, port=sma_port)
    wait_for_volume_in_os()


def detach_volume(
    ipu_storage_container_ip: str, sma_port: int, device_handle: str, volume_id: str
) -> None:
    request = {
        "method": "DetachVolume",
        "params": {"device_handle": device_handle, "volume_id": uuid2base64(volume_id)},
    }
    send_sma_request(
        request=request,
        addr=ipu_storage_container_ip,
        port=sma_port,
    )


def is_port_open(ip_addr: str, port: int, timeout: float = 1.0) -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(timeout)
        return s.connect_ex((ip_addr, port))


def send_request(client, request):
    response = client.call(request["method"], request.get("params", {}))
    return response


def send_rpc_request(request, addr: str, port: int, timeout: float = 60.0):
    client = rpc.rpc.client.JSONRPCClient(addr, port, timeout)
    return send_request(client, request)


def send_sma_request(request, addr: str, port: int):
    client = sma_client.Client(addr, port)
    with SuppressProxyEnvVariables():
        return send_request(client, request)


def send_requests(requests, function, *args, **kwargs):
    return [function(request, *args, **kwargs) for request in requests]


class SuppressProxyEnvVariables:
    def __init__(self) -> None:
        self._proxy_env_var_names = {
            "NO_PROXY",
            "no_proxy",
            "HTTP_PROXY",
            "http_proxy",
            "HTTPS_PROXY",
            "https_proxy",
        }
        self._saved_env_vars = dict()

    def __enter__(self):
        for proxy_env_var_name in self._proxy_env_var_names:
            value_to_save = os.environ.pop(proxy_env_var_name, None)
            if value_to_save is not None:
                self._saved_env_vars[proxy_env_var_name] = value_to_save

    def __exit__(self, *args, **kwargs):
        os.environ.update(self._saved_env_vars)
