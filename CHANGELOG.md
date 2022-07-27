# IPDK CHANGELOG

## v22.07

### Storage

Initial contribution of storage recipes based on KVM-target.

Hot-plug recipe describes how to deploy containers between different machines
and demonstrates virtio-blk hot-plug to a running host.

Fio recipe extends hot-plug scenario and describes how to run fio traffic by
means of host-target container through a hot-plugged virtio-blk device.

Scale-out recipe similar to hot-plug recipe but describing how to
hot-plug/hot-unplug 64 virtio-blk devices.

Unit and integrations tests executable in one-host environment based on
docker-compose are added.
