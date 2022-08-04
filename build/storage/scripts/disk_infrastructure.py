import base64
import importlib
import logging
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
    cmd = 'lsblk --output "NAME"'
    out = socket_functions.send_command_over_unix_socket(
        sock=sock, cmd=cmd, wait_for_secs=1
    )
    number_of_virtio_blk_devices = len(re.findall("vd", out))
    return number_of_virtio_blk_devices


def is_virtio_blk_attached(sock: str) -> int:
    if get_number_of_virtio_blk(sock) == 0:
        logging.error("virtio-blk is not found")
        return 1
    logging.info("virtio-blk is found")
    return 0


def is_virtio_blk_not_attached(sock: str) -> int:
    if is_virtio_blk_attached(sock):
        return 0
    return 1


def check_number_of_virtio_blk_devices(
    vm_serial: str, expected_number_of_devices: int
) -> int:
    number_of_devices = get_number_of_virtio_blk(vm_serial)
    if number_of_devices != expected_number_of_devices:
        logging.error(
            f"Required number of devices '{expected_number_of_devices}' does "
            f"not equal to actual number of devices '{number_of_devices}'"
        )
        return 1
    else:
        logging.info(f"Number of attached virtio-blk devices is '{number_of_devices}'")
        return 0


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
    for request in requests:
        send_rpc_request(
            request=request,
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
                "num_blocks": ramdrive_size_in_mb * 1024 * 1024 // 512,
                "block_size": 512,
            },
        },
        {
            "method": "nvmf_subsystem_add_ns",
            "params": {"nqn": nqn, "namespace": {"bdev_name": ramdrive_name}},
        },
        {"method": "bdev_get_bdevs", "params": {"name": ramdrive_name}},
    ]
    for request in requests:
        response = send_rpc_request(
            request=request,
            addr=ip_addr,
            port=storage_target_port,
        )
    device_uuid = response[0]["uuid"]
    return device_uuid


def uuid2base64(device_uuid: str) -> str:
    return base64.b64encode(uuid.UUID(device_uuid).bytes).decode()


def create_virtio_blk_without_disk_check(
    ipu_storage_container_ip: str,
    volume_id: str,
    physical_id: str,
    virtual_id: str,
    hostnqn: str,
    traddr: str,
    trsvcid: str,
    sma_port: int,
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
    return device_handle


def delete_virtio_blk(
    ipu_storage_container_ip: str, device_handle: str, sma_port: int
) -> int:
    request = {"method": "DeleteDevice", "params": {"handle": device_handle}}
    try:
        send_sma_request(request, ipu_storage_container_ip, sma_port)
    except Exception as ex:
        logging.error(ex)
        return 1
    return 0


def wait_for_virtio_blk_in_os(timeout: float) -> None:
    time.sleep(timeout)


def create_virtio_blk(*args, **kwargs) -> str:
    disk_handle = create_virtio_blk_without_disk_check(*args, **kwargs)
    wait_for_virtio_blk_in_os(2)
    return disk_handle


def is_port_open(ip_addr: str, port: int, timeout: float) -> int:
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
    return send_request(client, request)
