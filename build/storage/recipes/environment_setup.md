# Environment preparation
Currently the recipe environment should be represented by 2 separate machines,
referred  as `storage-target` and `proxy-container`,
located in the same network. For each of them the steps from
[System setup](#system-setup) section have to be performed.

# System setup
The basic requirement for running the recipes is a modern Linux distribution
with docker support.
So far, the recipe has been successfully tested on the following systems:
- Fedora 33
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

1. Download repositories on both platforms: `proxy-container` and
`storage-target`

2. Run docker containers providing configuration scripts:

On `storage-target`
```
$ scripts/run_storage_target_container.sh
```

On `proxy-container`
```
$ SHARED_VOLUME=<dir_to_expose_vhost_and_vm_monitors> \
scripts/run_proxy_container.sh
```

`SHARED_VOLUME` points to a directory where vhost storage device and vm monitor
will be exposed.

3. Run the vm instance on `proxy-container` platform
```
$ VM_DIR=<dir_to_expose_vhost_and_vm_monitors> scripts/vm/run_vm.sh
```

`VM_DIR` points to a directory where vhost storage device and vm monitor
will be exposed(exactly one specified in `SHARED_VOLUME` to run `proxy-container`).

login:password pair for the vm is `root:root`.
Run `host-target` container within the vm
```
$ run_host_target_container.sh &
```

4. Prepare environment to send commands to the storage containers.
For that purpose we need to have spdk rpc.py and grpc-cli tools available.
`test-driver` container from the [integration tests](../tests/it/README.md#introduction)
fits for this purpose well since it contains all required tools.
In the recipes this `test-driver` will be referred as `cmd-sender`

Run the integration tests to build that container on `proxy-container` machine.
```
$ tests/it/run.sh
```

Run `test-driver` on `proxy-container` machine
```
$ docker run -it --privileged --network host --entrypoint /bin/bash test-driver
```

Source supplementary scripts in running `test-driver` container
```
$ source /scripts/disk_infrastructure.sh
```
