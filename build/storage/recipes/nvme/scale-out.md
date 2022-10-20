# Scale-out recipe

This recipe describes how to attach 64 NVMe devices with namespaces to a host
with IPDK containers. This scenario is similar to
[hot-plug scenario](hot-plug.md) but 64 NVMe devices are attached.

For this recipe, two physical machines are required.
They are referred to as `storage-target-platform` and `ipu-storage-container-platform`.
The containers running on those platforms are named `storage-target` and
`ipu-storage-container`, respectively.

To apply this scenario, the following steps need to be applied:

1. Perform all steps described in [environment setup](../environment_setup.md)

2. Make sure there is no NVMe device attached.
Run in [vm console](../environment_setup.md#vm-console)
```
$ lsblk; echo""; ls /dev/nvme*
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

ls: cannot access '/dev/nvme*': No such file or directory
```

3. Create a subsystem and expose it over NVMe/TCP.
Send from your `cmd-sender`
```
$ create_and_expose_sybsystem_over_tcp \
	<storage_target_platform_ip> nqn.2016-06.io.spdk:cnode0
```

4. Create 64 ramdrives on `storage-target` and attach to the subsystem.
Send from your `cmd-sender`
```
$ ramdrives=() ; \
for ((i=0; i < "64"; i++)) ; do \
ramdrives+=("$(create_ramdrive_and_attach_as_ns_to_subsystem \
        <storage_target_platform_ip> Malloc$i 4 nqn.2016-06.io.spdk:cnode0)"); \
done
```


5. Create 64 NVMe devices attached to the vm.
Send from your `cmd-sender`
```
$ devs=() ; \
for ((i=0; i < "64"; i++)) ; do \
    devs+=("$(create_nvme_device <ipu_storage_container_platform_ip> \
         8080 <host_ip_where_vm_is_run> 50051 $i 0)") ; \
done
```


6. Verify 64 NVMe devices are visible in the vm.
Run in [vm console](../environment_setup.md#vm-console)
```
$ ls /dev/nvme* | wc -l
```
The Expected output is
```
64
```


7. Attach one namespace to each NVMe device.
Send from your `cmd-sender`
```
$ for ((i=0; i < "64"; i++)) ; do \
	attach_volume <ipu_storage_container_platform_ip> "${devs[$i]}" "${ramdrives[$i]}" \
    nqn.2016-06.io.spdk:cnode0 <storage_target_platform_ip> 4420 ; \
done
```


8. Validate number of namespaces attached to the NVMe devices
Send from vm console
```
$ lsblk | grep -c nvme
```
The Expected output is
```
64
```


9. Detach all volumes.
Send from your `cmd-sender`
```
$ for ((i=0; i < "64"; i++)) ; do \
    detach_volume <ipu_storage_container_platform_ip> "${devs[$i]}" "${ramdrives[$i]}" \
done
```


10. Attach 32 namespaces to a single NVMe device.
Send from your `cmd-sender`
```
$ for ((i=0; i < "32"; i++)) ; do \
	attach_volume <ipu_storage_container_platform_ip> "${devs[0]}" "${ramdrives[$i]}" \
    nqn.2016-06.io.spdk:cnode0 <storage_target_platform_ip> 4420 ; \
done
```


11. Make sure all 32 namespaces are attached to a single NVMe device.
Send from vm console
```
$ lsblk | grep -c nvme0n*
```
The Expected output is
```
32
```


12. Detach all namespaces and delete all devices.
Send from your `cmd-sender`
```
$ for ((i=0; i < "32"; i++)) ; do \
    detach_volume <ipu_storage_container_platform_ip> "${devs[0]}" "${ramdrives[$i]}"; \
done ; \
for ((i=0; i < "64"; i++)) ; do \
    delete_nvme_device <ipu_storage_container_platform_ip> \
         8080 <host_ip_where_vm_is_run> 50051 "${devs[$i]}"; \
done

```


13. Verify there is no NVMe device attached.
Run in [vm console](../environment_setup.md#vm-console)
```
$ lsblk; echo""; ls /dev/nvme*
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

ls: cannot access '/dev/nvme*': No such file or directory
```

