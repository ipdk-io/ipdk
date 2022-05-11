# Hot-plug recipe
This recipe describes how to perform virtio-blk hot-plug to a running KVM host.
The virtio-blk device is backed up by an ideal target on `storage-target-platform`
machine exposed over NVMe/TCP.

For this recipe 2 machines required. They are referred as
`storage-target-platform` and `proxy-container-platform`.
The containers running on those platforms are named `storage-target` and
`proxy-container` respectively.

To apply this scenario the following steps need to be applied:

1. Perform all steps described in [environment setup](environment_setup.md)

2. Make sure there is no virtio-blk device attached
Run in [vm console](environment_setup.md#vm-console)
$ lsblk
```
Expected output
```
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0   4G  0 disk
└─sda1   8:1    0   4G  0 part /
```

3. Create subsystem and expose it to `proxy-container`
Send from your `cmd-sender`
```
$ create_subsystem_and_expose_to_another_machine \
	<storage_target_platform_ip> nqn.2016-06.io.spdk:cnode0 \
	<proxy_container_platform_ip> Nvme0
```

4. Create ramdrive on `storage-target` and attach to the subsystem
Send from your `cmd-sender`
```
$ create_ramdrive_and_attach_as_ns_to_subsystem \
	<storage_target_platform_ip> Malloc0 16 nqn.2016-06.io.spdk:cnode0
```

5. Attach exposed ramdrive to the vm
Send from your `cmd-sender`
```
$ attach_ns_as_virtio_blk \
	<proxy_container_platform_ip> VirtioBlk0 Nvme0n1 50051 \
	vm_monitor
```

6. Check if virtio-blk is attached to the vm
Open the [vm console](environment_setup.md#vm-console) machine and run the following command
```
$ lsblk
```
The expected output is
```
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0   4G  0 disk
└─sda1   8:1    0   4G  0 part /
vda    252:0    0  16M  0 disk
```

7. Perform unplug
Run the command below on `cmd-sender` to hot-unplug device
```
dettach_virtio_blk <proxy_container_platform_ip> 50051 vm_monitor VirtioBlk0
```

8. Check there is no virtio-blk device
Open the [vm console](environment_setup.md#vm-console) and run the following command
```
$ lsblk
```
The expected output is
```
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0   4G  0 disk
└─sda1   8:1    0   4G  0 part /
```
