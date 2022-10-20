# Hot-plug recipe

This recipe describes how to perform NVMe hot-plug to a running KVM host.
The NVMe device namespaces are backed up by ideal targets on
`storage-target-platform` machine exposed over NVMe/TCP.

For this recipe, two physical machines are required.
They are referred to as `storage-target-platform` and `ipu-storage-container-platform`.
The containers running on those platforms are named `storage-target` and
`ipu-storage-container` respectively.

To apply this scenario the following steps need to be applied:

1. Perform all steps described in [environment setup](../environment_setup.md)


2. Make sure there is no NVMe device/volumes attached.
Run in [vm console](../environment_setup.md#vm-console)
```
$ lsblk; echo""; ls /dev/nvme*
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

ls: cannot access '/dev/nvme*': No such file or directory
```


3. Create subsystem and expose it over NVMe/TCP.
Send from your `cmd-sender`
```
$ create_and_expose_sybsystem_over_tcp \
	<storage_target_platform_ip> nqn.2016-06.io.spdk:cnode0
```


4. Create ramdrive on `storage-target` and attach to the subsystem.
Send from your `cmd-sender`
```
$ malloc0=$(create_ramdrive_and_attach_as_ns_to_subsystem \
	<storage_target_platform_ip> Malloc0 64 nqn.2016-06.io.spdk:cnode0)
```


5. Attach NVMe device to the virtual host.
Send from your `cmd-sender`
```
$ nvme0=$(create_nvme_device <ipu_storage_container_platform_ip> \
     8080 <host_ip_where_vm_is_run> 50051 "0" "0")
```


6. Check NVMe device appeared within the vm.
Send from vm console
```
$ ls /dev/nvme0*
```
The expected output is
```
/dev/nvme0
```


7. Attach ramdrive as a volume to NVMe device.
Send from your `cmd-sender`
```
$ attach_volume <ipu_storage_container_platform_ip> "$nvme0" "$malloc0" \
    nqn.2016-06.io.spdk:cnode0 <storage_target_platform_ip> 4420
```


8. Verify the volume is visible as NVMe namespace from vm.
Send from vm console
```
$ lsblk
```
The expected output is
```
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda       8:0    0    5G  0 disk
├─sda1    8:1    0    1M  0 part
├─sda2    8:2    0 1000M  0 part /boot
├─sda3    8:3    0  100M  0 part /boot/efi
├─sda4    8:4    0    4M  0 part
└─sda5    8:5    0  3.9G  0 part /var/lib/docker/btrfs
                                 /home
                                 /
zram0   252:0    0  964M  0 disk [SWAP]
nvme0n1 259:0    0   64M  0 disk
```


9. Hot-unplug volume.
Send from `cmd-sender`
```
$ detach_volume <ipu_storage_container_platform_ip> "$nvme0" "$malloc0"
```


10. Make sure that volume is detached, however, the device is still visible.
Send from vm console
```
$ lsblk; echo ""; ls /dev/nvme*
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

/dev/nvme0
```


11. Hot-unplug NVMe device.
Send from `cmd-sender`
```
$ delete_nvme_device <ipu_storage_container_platform_ip> \
     8080 <host_ip_where_vm_is_run> 50051 "$nvme0"
```


12. Check no NVMe device exists within the vm.
Send from vm console
```
$ ls /dev/nvme*
```
The expected output is
```
ls: cannot access '/dev/nvme*': No such file or directory
```
