# Scale-out recipe

This recipe describes how to attach 64 virtio-blk disks to a host
with IPDK containers. This scenario is similar to
[hot-plug scenario](hot-plug.md) but 64 virtio-blk devices are attached.

For this recipe, two physical machines are required.
They are referred to as `storage-target-platform` and `ipu-storage-container-platform`.
The containers running on those platforms are named `storage-target` and
`ipu-storage-container`, respectively.

To apply this scenario, the following steps need to be applied:

1. Perform all steps described in [environment setup](environment_setup.md)

2. Make sure there is no virtio-blk device attached.
Run in [vm console](environment_setup.md#vm-console)
```
$ lsblk
```
Expected output
```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0    5G  0 disk
├─sda1   8:1    0    1M  0 part
├─sda2   8:2    0 1000M  0 part /boot
├─sda3   8:3    0  100M  0 part /boot/efi
├─sda4   8:4    0    4M  0 part
└─sda5   8:5    0  3.9G  0 part /var/lib/docker/btrfs
                                /home
                                /
zram0  252:0    0  964M  0 disk [SWAP]
```

3. Create a subsystem and expose it over NVMe/TCP.
Send from your `cmd-sender`
```
$ create_and_expose_sybsystem_over_tcp \
	<storage_target_platform_ip> nqn.2016-06.io.spdk:cnode0
```

4. Create 64 ramdrives on `storage-target` and attach to the subsystem
Send from your `cmd-sender`
```
$ ramdrives=() ; \
for ((i=0; i < "64"; i++)) ; do \
ramdrives+=("$(create_ramdrive_and_attach_as_ns_to_subsystem \
        <storage_target_platform_ip> Malloc$i 4 nqn.2016-06.io.spdk:cnode0)"); \
done
```

5. Attach exposed ramdrives to the vm.
Send from your `cmd-sender`
```
virtio_blks=() ; \
for ((i=0; i < "64"; i++)) ; do \
virtio_blks+=("$(create_virtio_blk_without_disk_check <ipu_storage_container_platform_ip> \
        "${ramdrives[$i]}" ${i} 0 nqn.2016-06.io.spdk:cnode0 \
        "<storage_target_platform_ip>")") ; \
done
```

6. Check if virtio-blk is attached to the vm.
Open the [vm console](environment_setup.md#vm-console) and run the following command
to calculate number of virtio-blk devices attached to the vm.
```
$ lsblk | grep vd -c
```
The expected output is
```
64
```
Also `lsblk` command can be run to observe all block devices.

7. Perform unplug.
Run the command below on `cmd-sender` to hot-unplug device
```
for ((i=0; i < "64"; i++)) ; do \
    delete_virtio_blk <ipu_storage_container_platform_ip> "${virtio_blks[$i]}"; \
done
```

8. Check that there is no virtio-blk device.
Open the [vm console](environment_setup.md#vm-console) and run the following command
```
$ lsblk
```
The expected output is
```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0    5G  0 disk
├─sda1   8:1    0    1M  0 part
├─sda2   8:2    0 1000M  0 part /boot
├─sda3   8:3    0  100M  0 part /boot/efi
├─sda4   8:4    0    4M  0 part
└─sda5   8:5    0  3.9G  0 part /var/lib/docker/btrfs
                                /home
                                /
zram0  252:0    0  964M  0 disk [SWAP]
```
