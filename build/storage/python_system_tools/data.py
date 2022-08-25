import json
from pathlib import Path

path = Path.cwd()
data_path = path.parent / "python_system_tools/data.json"
with open(file=data_path) as f:
    data = json.load(f)

ip_address_proxy = data["proxy_address"]
proxy_docker_image = data["proxy_docker_image"]

ip_address_storage = data["storage_address"]
storage_docker_image = data["storage_docker_image"]

ip_address_cmd_sender = data["cmd_address"]
cmd_docker_name = data["cmd_docker_name"]

user_name = data["user"]
password = data['password']
nqn = 'nqn.2016-06.io.spdk:cnode0'
spdk_port = 5260
nvme_port = '4420'
sma_port = 8080
