# Environment preparation
Currently the recipe environment should be represented by 2 separate machines,
referred  as `storage-target-platform` and `proxy-container-platform`,
located in the same network. For each of them the steps from
[System setup](#system-setup) section have to be performed.
The containers running on those platforms are named `storage-target` and
`proxy-container` respectively.

# System setup
The basic requirement for running the recipes is a modern Linux distribution
with docker support.
So far, the recipe has been successfully tested on the following systems:
- Fedora 34
- Ubuntu 18.04

To run the recipe some basic system preparations are required, in particular:

## Virtualization support
Make sure that VT-x/AMD-v support is enabled in BIOS
```
$ lscpu | grep -i virtualization
Virtualization:                  VT-x
```
and that kvm modules are loaded
```
$ lsmod | grep -i kvm
kvm_intel             217088  0
kvm                   614400  1 kvm_intel
irqbypass              16384  1 kvm
```

## Tool installation
Make sure that following tools are installed on your system or install them
using the corresponding package manager.

### wget
Installation on Fedora
```
$ sudo dnf install wget
```
or on Ubuntu
```
$ sudo apt install wget
```

### docker
```
$ sudo dnf install docker
```
or
```
$ sudo apt install docker
```
**Note:**
Make sure that required proxy settings are configured for docker.
Please, refer to [this](https://docs.docker.com/config/daemon/systemd/#httphttps-proxy)
page.

### libguestfs-tools
```
$ sudo dnf install libguestfs-tools-c
```
or
```
$ sudo apt install libguestfs-tools
```

**Note:**
To run `libguestfs` tools without root privileges, you may need to workaround
the problem of
Linux kernel image not being readable by issuing:
```
$ sudo chmod +r /boot/vmlinuz-*
```

## Setting security policies
Make sure that required security permissions are configured to enable VM network
connectivity or disable them temporarily.
On Fedora SELinux can be disabled by means of the following command
```
$ sudo setenforce 0
```
For Ubuntu AppArmor is often used and can be disabled by issuing
```
$ sudo systemctl stop apparmor
```

# Deploy containers on the machines

1. Download repositories on both platforms: `proxy-container-platform` and
`storage-target-platform`

2. Run docker containers providing configuration scripts:

On `storage-target-platform`
```
$ scripts/run_storage_target_container.sh
```

On `proxy-container-platform`
```
$ SHARED_VOLUME=<dir_to_expose_vhost> \
scripts/run_proxy_container.sh
```

`SHARED_VOLUME` points to a directory where vhost storage devices
will be exposed.

It is also possible for `storage-target` to specify ip addresses and ports where
spdk service is exposed on by specifying `SPDK_IP_ADDR` and `SPDK_PORT`
environment variables.
e.g.
```
SPDK_IP_ADDR="127.0.0.1" SPDK_PORT=5261 scripts/run_storage_target_container.sh
```
By default, `SPDK_IP_ADDR` is set to `0.0.0.0` and `SPDK_PORT` is set to `5260`

3. Run the vm instance on `proxy-container-platform` platform
```
$ SHARED_VOLUME=<dir_to_expose_vhost> scripts/vm/run_vm.sh
```

`SHARED_VOLUME` points to a directory where vhost storage devices
will be exposed(exactly one specified in `SHARED_VOLUME` to run
`proxy-container`).

<a name="vm-console">
Finally vm console will be opened.
</a>

login:password pair for the vm is `root:root`.
Run `host-target` container within the vm console
```
$ run_host_target_container.sh &
```

4. Prepare environment to send commands to the storage containers.
For that purpose we need to have spdk rpc.py and grpc-cli tools available.
`test-driver` image from the [integration tests](../tests/it/README.md#introduction)
fits for this purpose well since it contains all required tools.
Let's use `test-driver` image instance to send all required commands.
In the recipes this `test-driver` will be referred as `cmd-sender` to
increase comprehension of the text. However, we should keep in mind that
`cmd-sender` is a running instance of `test-driver` image.

To use test-driver [install docker-compose](../tests/it/README.md#docker-compose-setup)
and run the integration tests to build that container on `proxy-container-platform`
machine.
```
$ tests/it/run.sh
```

Run `test-driver` on `proxy-container-platform` machine
```
$ docker run -it --privileged --network host --entrypoint /bin/bash test-driver
```

Source supplementary scripts in running `test-driver` container
```
$ source /scripts/disk_infrastructure.sh
```
