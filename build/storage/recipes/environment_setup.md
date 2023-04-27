# Environment preparation
Currently the recipe environment should be represented by 2 separate machines,
referred  as `storage-target-platform` and `ipu-storage-container-platform`,
located in the same network. For each of them the steps from
[System setup](#system-setup) section have to be performed.
The containers running on those platforms are named `storage-target` and
`ipu-storage-container` respectively.

# System setup
The basic requirement for running the recipes is a modern Linux distribution
with docker support.
So far, the recipe has been successfully tested on the following systems:
- Fedora 34
- Ubuntu 18.04

To run the recipe some basic system preparations are required, in particular:

## Security features
Please consider enabling security-enhancing features in your HW deployment
environment for the solution. In particular, Data Execution Prevention (DEP)
and Address Space Layout Randomization (ASLR) should be enabled on a server
supporting this functionalities to harden your environment against buffer
overflow attacks.

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

### kernel-headers
```
$ sudo dnf install kernel-headers
$ sudo dnf update
```
or on Ubuntu
```
$ sudo apt install kernel-headers
$ sudo apt-get update
```

### docker
Docker 21.10.10 or greater is required.

Installation guideline for [Fedora](https://docs.docker.com/engine/install/fedora/).

Installation guideline for [Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

---
**NOTE**

Make sure that required proxy settings are configured for docker.
Please, refer to [this](https://docs.docker.com/config/daemon/systemd/#httphttps-proxy)
page.

---

### libguestfs-tools
```
$ sudo dnf install libguestfs-tools-c
```
or
```
$ sudo apt install libguestfs-tools
```

---
**NOTE**

To run `libguestfs` tools without root privileges, you may need to workaround
the problem of Linux kernel image not being readable by issuing:
```
$ sudo chmod +r /boot/vmlinuz-*
```

---

### oracle/qemu
Install required tools.
```
$ dnf install -y git glib2-devel libfdt-devel pixman-devel zlib-devel bzip2 \
    ninja-build python3 make gcc diffutils libaio-devel numactl-devel
```
or
```
$ apt install -y git libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev \
    ninja-build python3 make gcc libaio-dev libnuma-dev
```

Run the following script to install corresponding qemu version
```
$ scripts/prepare_to_build.sh
$ scripts/vm/install_qemu.sh
```

## Setting security policies
Make sure that required security permissions are configured to enable vm network
connectivity or any other aspects of the scenario flow.
For a secure integration and deployment with their target environments, users
should make sure to apply the highest level of security settings by not
disabling SELinux or other OS-supported security solutions but configuring them
accordingly.

# Deploy containers on the machines

1. Download repositories on both platforms: `ipu-storage-container-platform` and
`storage-target-platform`

2. Run docker containers providing configuration scripts:

On `storage-target-platform`
```
$ scripts/run_storage_target_container.sh
```

On `ipu-storage-container-platform`
```
$ SHARED_VOLUME=<dir_to_expose_vhost> \
scripts/run_ipu_storage_container.sh
```

`SHARED_VOLUME` points to a directory where vhost storage devices
will be exposed.

---
**NOTE**

By default, images for `storage-target` and `ipu-storage-container`
will be pulled from IPDK public registry for the scripts in the main branch.
However, those images are not optimized for a local CPU and if such an
optimization is required, then `OPTIMIZED_SPDK=true` environment variable should
be exported before running the scripts above.

---

It is also possible for `storage-target` to specify ip addresses and ports where
spdk service is exposed on by specifying `SPDK_IP_ADDR` and `SPDK_PORT`
environment variables.
e.g.
```
SPDK_IP_ADDR="127.0.0.1" SPDK_PORT=5261 scripts/run_storage_target_container.sh
```
By default, `SPDK_IP_ADDR` is set to `0.0.0.0` and `SPDK_PORT` is set to `5260`

3. Run the vm instance on `ipu-storage-container-platform`.
```
$ SHARED_VOLUME=<dir_to_expose_vhost> scripts/vm/run_vm.sh
```
By default, password for root user is `root`
`SHARED_VOLUME` points to a directory where vhost storage devices
will be exposed(exactly one specified in `SHARED_VOLUME` to run
`ipu-storage-container`).

If it is needed to use no-default password, `ASK_FOR_VM_ROOT_PASSWORD=true` variable should be set
and a user will be prompt to provide root password at build time.
```
$ SHARED_VOLUME=<dir_to_expose_vhost> ASK_FOR_VM_ROOT_PASSWORD=true scripts/vm/run_vm.sh
```

<a name="vm-console">
Finally vm console will be opened.
</a>

4. Prepare environment to send commands to the containers.
Use `cmd-sender` on `ipu-storage-container-platform` machine.
```
$ scripts/run_cmd_sender.sh
```
