# Supported recipes
Currently, the following scenarios are represented:

### Virtio-blk recipes
* [hot-plug](./virtio-blk/hot-plug.md) - demonstrates a simple virtio-blk
hot-plug to a running host.
* [fio](./virtio-blk/fio.md) - extends `hot-plug` scenario and describes how to run
fio traffic by means of `host-target` container through a hot-plugged virtio-blk
device.
* [scale-out](./virtio-blk/scale-out.md) - similar to hot-plug recipe but describing
how to hot-plug/hot-unplug 64 virtio-blk devices.
* [qos](./virtio-blk/qos.md) - explains how to set QoS limits for exposed virtio-blk devices.

### NVMe recipes
NVMe recipes are very similar to the ones for virtio-blk device.
* [hot-plug](./nvme/hot-plug.md) - demonstrates a simple NVMe device/volume
hot-plug to a running host.
* [fio](./nvme/fio.md) - extends `hot-plug` scenario and describes how to run
fio traffic by means of `host-target` container through a hot-plugged NVMe
device.
* [scale-out](./nvme/scale-out.md) - similar to hot-plug recipe but describing
how to hot-plug/hot-unplug 64 NVMe devices and attaching 32 volumes to a single
NVMe device.
* [qos](./nvme/qos.md) - explains how to set QoS limits for exposed NVMe devices and volumes attached to it.


In all cases host target platform is implied as KVM.

The picture below demonstrates the configuration exercised in these recipes
![System configuration for recipes](./system_configuration.png "System configuration for recipes")
