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

### Networking Recipe (P4-OVS)

#### Feature support

* Linux Networking support(L2 Forwarding,VXLAN,ECMP, and Routing)
* Hotplug support for vhost-user ports
* OpenConfig GNMI CLI support for TAP ports and physical link ports
* Port Configuration dump
* Indirect Counter support
* TDI integration
* PTF support (Python based packet test framework)
* GTEST based Unit test framework
* Action Profile and Action Selector

#### Limitations

* Partial implementation of TCP state machine for connection tracking
* Hotplug feature works with specific configuration and user cannot del/re-add
the hotplug port again <https://github.com/ipdk-io/ovs/issues/38>
