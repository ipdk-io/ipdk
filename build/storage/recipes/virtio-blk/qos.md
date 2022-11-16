# QoS recipe

This recipe describes how to set different QoS limits on an exposed virtio-bk device.

For this recipe, two physical machines are required.
They are referred to as `storage-target-platform` and `ipu-storage-container-platform`.
The containers running on those platforms are named `storage-target` and
`ipu-storage-container` respectively.

To apply this scenario the following steps need to be applied:

1. Perform all steps described in [environment setup](../environment_setup.md)

2. Run [fio scenario](fio.md) to observe device throughput.
In the fio command `rw` field can be replaced with `randread` or `randwrite` to exercise device only with reads or writes.

3. Set required QoS limits.
IPDK Storage Solution leverages SPDK SMA to get supported [QoS capabilities](https://github.com/spdk/spdk/blob/aed4ece93c659195d4b56399a181f41e00a7a25e/python/spdk/sma/proto/sma.proto#L148) and set [required QoS limits](https://github.com/spdk/spdk/blob/aed4ece93c659195d4b56399a181f41e00a7a25e/python/spdk/sma/proto/sma.proto#L124).

To request supported virtio-blk capabilities, execute the following cmd from `cmd-sender`:
```
$ get_virtio_blk_qos_capabilities <ipu_storage_container_platform_ip> 8080
```
and expected output for KVM case is
```
{"max_device_caps": {"rw_iops": true, "rd_bandwidth": true, "wr_bandwidth": true, "rw_bandwidth": true}, "max_volume_caps": {"rw_iops": true, "rd_bandwidth": true, "wr_bandwidth": true, "rw_bandwidth": true}}

```
which says that for this device type per-volume and per-device QoS maximum limits are supported and we can set the following limits:
* rw_iops - maximum Read/write kIOPS
* rd_bandwidth - read bandwidth (MB/s)
* wr_bandwidth - write bandwidth (MB/s)
* rw_bandwidth - read/write bandwidth (MB/s)

to set QoS limit, run the command bellow replacing limit values in `<>` with required values from the supported capabilities.
If a limit is not reported as supported in the capabilities, it must be set as 0
```
$ set_max_qos_limits <ipu_storage_container_platform_ip> 8080 $virtio_blk0 <volume_id> <rd_iops> <wr_iops> <rw_iops> <rd_bandwidth> <wr_bandwidth> <rw_bandwidth>
```
since virtio-blk devices support device level capabilities, so `volume_id` can be left empty.
```
$ set_max_qos_limits <ipu_storage_container_platform_ip> 8080 $virtio_blk0 "" <rd_iops> <wr_iops> <rw_iops> <rd_bandwidth> <wr_bandwidth> <rw_bandwidth>
```

This is an exemplary command to set the read bandwidth to 16MB/s on `malloc0` volume.
```
$ set_max_qos_limits <ipu_storage_container_platform_ip> 8080 $virtio_blk0 $malloc0 0 0 0 16 0 0
```
or for device level
```
$ set_max_qos_limits <ipu_storage_container_platform_ip> 8080 $virtio_blk0 "" 0 0 0 16 0 0
```

4. Check if the limit was applied
Re-run fio cmd from the fio scenario and observe if QoS settings were applied to virtio-blk device.
