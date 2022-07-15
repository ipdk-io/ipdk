# IPDK Release Notes

## v22.07

### Storage

In this release initial recipes for storage were added. In particular,
the solution enables:

* Containerized execution environment consisting of 3 storage containers
deployable on different physical systems.
* Exposition of emulated virtio-blk devices to a VM running in a host-target
container from ipu-storage container backed by a remote NVMe-oTCP connection
to a remote storage-target container.
* Dynamic provisioning of up to 64 or more virtio-blk devices to the VM by
hot-(un)plug mechanism.
* Creation of a one-host test environment for integration tests based on
docker-compose including running exemplary fio traffic and dynamic provisioning.
* Customization possibility for enablement of virtio-blk HW-acceleration
through dedicated HW over HW-agnostic interfaces.
