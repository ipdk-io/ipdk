import base64
import json
import logging
import re
import socket
import subprocess
import time
import uuid

from scripts import socket_functions

logging.root.setLevel(logging.CRITICAL)


def get_number_of_virtio_blk(socket: str) -> int:
    cmd = 'lsblk --output "NAME,VENDOR,SUBSYSTEMS"'
    out = socket_functions.send_command_over_unix_socket(
        sock=socket, cmd=cmd, wait_for_secs=1
    )
    number_of_virtio_blk_devices = len(re.findall("block:virtio:pci", out))
    return number_of_virtio_blk_devices


def is_virtio_blk_attached(socket: str) -> int:
    if get_number_of_virtio_blk(socket) == 0:
        logging.error("virtio-blk is not found")
        return 1
    logging.info("virtio-blk is found")
    return 0


def is_virtio_blk_not_attached(socket: str) -> int:
    if is_virtio_blk_attached(socket):
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
    ip_addr: str, nqn: str, port_to_expose: int, storage_target_port: int
) -> None:
    subprocess.run(
        f"rpc.py -s {ip_addr} -p {storage_target_port} "
        f"nvmf_create_subsystem {nqn} -s SPDK00000000000001 -a -m 1024",
        check=True,
        shell=True,
    )
    subprocess.run(
        f"rpc.py -s {ip_addr} -p {storage_target_port} nvmf_create_transport -t TCP -u 8192",
        check=True,
        shell=True,
    )
    subprocess.run(
        f"rpc.py -s {ip_addr} -p {storage_target_port} nvmf_subsystem_add_listener "
        f"{nqn} -t TCP -f IPv4 -a {ip_addr} -s {port_to_expose}",
        check=True,
        shell=True,
    )


def create_ramdrive_and_attach_as_ns_to_subsystem(
    ip_addr: str,
    ramdrive_name: str,
    number_of_512b_blocks: int,
    nqn: str,
    storage_target_port: int,
) -> str:
    subprocess.run(
        f"rpc.py -s {ip_addr} -p {storage_target_port} bdev_malloc_create "
        f"-b {ramdrive_name} {number_of_512b_blocks} 512",
        check=True,
        shell=True,
        stderr=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
    )
    subprocess.run(
        f"rpc.py -s {ip_addr} -p {storage_target_port} "
        f"nvmf_subsystem_add_ns {nqn} {ramdrive_name}",
        check=True,
        shell=True,
    )
    data = subprocess.run(
        f"rpc.py -s {ip_addr} bdev_get_bdevs",
        capture_output=True,
        check=True,
        shell=True,
        text=True,
    ).stdout
    dict_list = json.loads(data)
    device_uuid = [d["uuid"] for d in dict_list if d["name"] == ramdrive_name][0]
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
    data = {
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
    data = subprocess.run(
        f"sma-client.py --address {ipu_storage_container_ip} --port {sma_port}",
        capture_output=True,
        check=True,
        input=json.dumps(data),
        shell=True,
        text=True,
    ).stdout
    device_handle = json.loads(data)["handle"]
    return device_handle


def delete_virtio_blk(
    ipu_storage_container_ip: str, device_handle: str, sma_port: int
) -> int:
    data = {"method": "DeleteDevice", "params": {"handle": device_handle}}
    return subprocess.run(
        f"sma-client.py --address {ipu_storage_container_ip} --port {sma_port}",
        check=True,
        input=json.dumps(data),
        shell=True,
        stdout=subprocess.DEVNULL,
        text=True,
    ).returncode


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
