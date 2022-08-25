import re
import sys
import os
import time

sys.path.append('../')

from python_system_tools.consts import SHARE_DIR_PATH, WORKSPACE_PATH
from python_system_tools.containers_deploy import ContainersDeploy
from python_system_tools.docker import Docker
from python_system_tools.extendedterminal import ExtendedTerminal
from python_system_tools.data import ip_address_proxy, ip_address_storage, ip_address_cmd_sender, user_name, password, \
    storage_docker_image, proxy_docker_image, cmd_docker_name


def set_for_test():
    containers_deploy = ContainersDeploy()
    containers_deploy.run_docker_containers()
    containers_deploy.run_docker_from_image(image=cmd_docker_name)

    cmd_terminal = ExtendedTerminal(address=ip_address_cmd_sender, user=user_name, password=password)
    cmd = f'SHARED_VOLUME={SHARE_DIR_PATH} UNIX_SERIAL=vm_socket scripts/vm/run_vm.sh &> /dev/null &'
    cmd_terminal.execute_as_root(cmd=cmd, cwd=f'{os.path.join(WORKSPACE_PATH, "ipdk/build/storage")}')
    time.sleep(60)


def tear_down_for_test():
    docker_proxy = Docker(address=ip_address_proxy, user=user_name, password=password)
    docker_storage = Docker(address=ip_address_storage, user=user_name, password=password)
    docker_cmd = Docker(address=ip_address_cmd_sender, user=user_name, password=password)

    docker_proxy.kill_container(
        container_id=docker_proxy.get_docker_id(docker_image=proxy_docker_image))
    docker_storage.kill_container(
        container_id=docker_storage.get_docker_id(docker_image=storage_docker_image))
    docker_cmd.kill_container(
        container_id=docker_cmd.get_docker_id(docker_image=cmd_docker_name))

    cmd_terminal = ExtendedTerminal(address=ip_address_cmd_sender, user=user_name, password=password)
    cmd_terminal.execute_as_root(cmd=f"rm -f vm_socket", cwd=SHARE_DIR_PATH)
    out, _ = cmd_terminal.execute(cmd="sudo netstat -plten | grep 5555")
    process_pid = re.search(pattern="(\d*)\/qemu-system", string=out).group(1)
    cmd_terminal.execute_as_root(cmd=f"kill -9 {process_pid}")




