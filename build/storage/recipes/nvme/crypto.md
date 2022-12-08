# Crypto recipe

This recipe describes how to create crypto volumes for NVMe devices.

For this recipe, two physical machines are required.
They are referred to as `storage-target-platform` and `ipu-storage-container-platform`.
The containers running on those platforms are named `storage-target` and
`ipu-storage-container` respectively.

To apply this scenario the following steps need to be applied:

1. Perform all steps described in [environment setup](../environment_setup.md)

2. Run [hot-plug scenario](hot-plug.md) until an NVMe device exists in the vm (step 5)

3. <a name="attach_crypto">Attach ramdrive as a crypto volume with AES CBC cipher to NVMe device.</a>
Send from your `cmd-sender`
```
$ attach_crypto_volume_with_aes_cbc_cipher <ipu_storage_container_platform_ip> "$nvme0" "$malloc0" \
    nqn.2016-06.io.spdk:cnode0  <storage_target_platform_ip> 1234567890abcdef1234567890abcde1 4420
```
`1234567890abcdef1234567890abcde1` can be replaced with any other suitable key.

Note: Underlying SMA supports also AES XTS cipher. If a used platform supports that cipher,
`attach_crypto_volume_with_aes_xts_cipher` can be used to attach a crypto volume.
In addition, after the key, an additional key2 should be specified.

4. Fill in drive with a pattern
Send from your `cmd-sender`
```
$ export pattern=0x12345678 ;
$ echo -e $(no_grpc_proxy="" grpc_cli call <host_ip_where_vm_is_run>:50051 \
        RunFio "diskToExercise: { deviceHandle: '$nvme0' volumeId: '$malloc0'} \
        fioArgs: '{\"rw\":\"write\", \"verify_pattern\": \"$pattern\" }'")
```
`0x12345678` can be replaced with any desirable pattern for fio.

5. <a name="verify">Verify the content of the drive</a>
Send from your `cmd-sender`
```
$ echo -e $(no_grpc_proxy="" grpc_cli call <host_ip_where_vm_is_run>:50051 \
        RunFio "diskToExercise: { deviceHandle: '$nvme0' volumeId: '$malloc0'} \
        fioArgs: '{\"verify_pattern\": \"$pattern\", \"verify_only\": 1  }'")
```

6. <a name="detach">Detach crypto volume</a>
```
$ detach_volume <ipu_storage_container_platform_ip> $nvme0 $malloc0
```

7. And attach the same ramdrive as a volume without crypto capabilities.
```
$ attach_volume <ipu_storage_container_platform_ip> "$nvme0" "$malloc0" \
    nqn.2016-06.io.spdk:cnode0 <storage_target_platform_ip> 4420
```

8. Verify the content of the drive
Run the command in [step 5](#verify) and observe command failure.

9. Detach volume
Run the command in [step 6](#detach) to detach volume from NVMe device.

10. Attach the same ramdrive as a crypto volume with AES CBC cipher to NVMe device.
Send from your `cmd-sender`
```
$ attach_crypto_volume_with_aes_cbc_cipher <ipu_storage_container_platform_ip> "$nvme0" "$malloc0" \
    nqn.2016-06.io.spdk:cnode0  <storage_target_platform_ip> 1234567890abcdef1234567890abcde2 4420
```
`1234567890abcdef1234567890abcde2` can be replaced with any other key different from the one used in [step 3](#attach_crypto).

11. Verify the content of the drive
Run the command in [step 5](#verify) and observe command failure.

12. Detach crypto volume
Run the command in [step 6](#detach) to detach volume from NVMe device.

13. Attach volume with a correct crypto key as described in [step 3](#attach_crypto)

14. Verify the content of the drive.
Run the command in [step 5](#verify) and observe command successfully completed.
