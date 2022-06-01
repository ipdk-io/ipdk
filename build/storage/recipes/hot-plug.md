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

3. Create subsystem and expose it over NVMe/TCP
Send from your `cmd-sender`
```
$ create_and_expose_sybsystem_over_tcp \
	<storage_target_platform_ip> nqn.2016-06.io.spdk:cnode0
```

4. Create ramdrive on `storage-target` and attach to the subsystem
Send from your `cmd-sender`
```
$ malloc0=$(create_ramdrive_and_attach_as_ns_to_subsystem \
	<storage_target_platform_ip> Malloc0 64 nqn.2016-06.io.spdk:cnode0)
```


5. Attach exposed ramdrive to the vm
Send from your `cmd-sender`
```
$ virtio_blk0=$(create_virtio_blk <proxy_container_platform_ip> "${malloc0}" \
	"0" "0" nqn.2016-06.io.spdk:cnode0 <storage_target_platform_ip>)
```


6. Check if virtio-blk is attached to the vm
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
vda    251:0    0   64M  0 disk
zram0  252:0    0  964M  0 disk [SWAP]
```

7. Perform unplug
Run the command below on `cmd-sender` to hot-unplug device
```
delete_virtio_blk <proxy_container_platform_ip> "${virtio_blk0}"
```

8. Check there is no virtio-blk device
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
