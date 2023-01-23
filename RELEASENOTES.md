# IPDK Release Notes

## v23.01

### Storage

The recipes enhance and extend the functionality enabled in the previous
release.
All virtio-blk flows from 22.07 have been enabled for NVMe incl. fio
traffic, hot-plug and scale-out scenarios.

Additional major features were enabled including:

* Quality-of-Service (QoS) support
  * Device-level rate and bandwidth limiters for virtio-blk devices
  * Volume-level rate and bandwidth limiters for NVMe devices
* Data-At-Rest Encryption (DARE) support for NVMe devices using
  * AES CBC cipher or
  * AES XTS cipher

Minor enhancements for this release include:

* Introduction of the cmd-sender container to improve use-of-use for the user
* Refactor of the object model to allow for more flexible design
* Adding `host-target` customization capability
* Adding the possibility to download pre-build images from GHCR
* Extending the solution with Python-based integration tests
* Passing arguments to SPDK from outside of containers
* Add ability to force build `host-target` container
* Providing fio config and results in JSON format
* Security-related improvements and fixes
* Documentation improvements

---

**NOTE:**\
IPDK is switching to the OPI Storage APIs. As part of that work SMA API will be
deprecated and will not be supported further.
IPDK contributors will work with OPI community to reach feature parity with the
current IPDK solution and plan to complete the full transition to OPI Storage
APIs by 23.07 release to allow for a full validation cycle.

---

#### Networking Recipe

##### Feature support

* Re-architecture of the Networking Recipe. The recipe is now modular and 
launched as the `InfraP4D` process
* Support for underlay traffic hashing with ECMP
* Support for dynamic underlay traffic via FRR, including routes learned with 
ECMP
* Flow dump support (including direct counters)
* TLS enablement to authenticate gRPC traffic

##### Limitations

* Linux Networking limitations are [summarized here]
(https://github.com/ipdk-io/networking-recipe/blob/main/p4src/linux_networking/README_LINUX_NETWORKING.md#limitations)
* Unable to delete OVS bridge using command `ovs-vsctl del-br` while actively 
running traffic. User needs to stop all the networking recipe processes to proceed 
with bridge deletion
* Flow dump & counters: A table-id/counter-id=0 is not yet supported
* TLS feature: Custom certificate location is unsupported for P4RT gRPC client. 
Certificates are expected in default location (/usr/share/stratum/certs)
* TLS feature: If InfraP4D is operating in insecure mode, gRPC clients may fail 
connecting
to the server. Move the certificates out of the default location 
(/usr/share/stratum/certs/ folder) in order to use insecure communication between 
gRPC clients and server

## v22.07

This is the initial release of the Infrastructure Programming Development Kit
(IPDK).  It includes recipes for P4 networking and storage.  As well, it has
support for continuous integration to gate changes to the IPDK repos.

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

Feature support:

* Linux Networking support(L2 Forwarding,VXLAN,ECMP, and Routing)
* Hotplug support for vhost-user ports
* OpenConfig GNMI CLI support for TAP ports and physical link ports
* Port Configuration dump
* Indirect Counter support
* TDI integration
* PTF support (Python based packet test framework)
* GTEST based Unit test framework
* Action Profile and Action Selector

Limitations:

* Partial implementation of TCP state machine for connection tracking
* Hotplug feature works with specific configuration and user cannot del/re-add
the hotplug port again <https://github.com/ipdk-io/ovs/issues/38>
* Ubuntu 20.04 and Fedora 33 are supported for container.

### CI/CD

CI has been enabled for the ipdk, ipdk-io.github.io, and ovs repos in this
initial release:

* ipdk - GitHub PR, GitHub Actions ala .github/workflows/* to generate the
  container images and Jenkins CI for the storage recipe
* ipdk-io.github.io - GitHub PR, GitHub Actions ala .github/workflows/* to
  run Jekyll to generate the website
* ovs - GitHub PR, Jenkins CI to do builds/testing
