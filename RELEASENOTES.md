# IPDK Release Notes

## v23.01

### Storage

The storage recipe enhances and extends the functionality enabled in the
22.07 release.
All virtio-blk flows from 22.07 have been enabled for NVMe including fio
traffic, hot-plug and scale-out scenarios.

Additional major features are enabled including:

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

### Networking Recipe

#### Feature support

* Re-architecture of the Networking Recipe. The recipe is now modular and
launched as the `infrap4d` process
* Support for underlay traffic hashing with ECMP
* Support for dynamic underlay traffic via FRR, including routes learned with
ECMP
* Flow dump support (including direct counters)
* TLS enablement to authenticate gRPC traffic

#### Limitations

* Linux Networking limitations are summarized here:
<https://github.com/ipdk-io/networking-recipe/blob/main/p4src/linux_networking/README_LINUX_NETWORKING.md#limitations>
* Unable to delete OVS bridge using command `ovs-vsctl del-br` while actively
running traffic. User needs to stop all the networking recipe processes to
proceed
with bridge deletion
* Flow dump & counters: A table-id/counter-id=0 is not yet supported
* TLS feature: Custom certificate location is unsupported for P4RT gRPC client.
Certificates are expected in default location (/usr/share/stratum/certs)
* TLS feature: If infrap4d is operating in insecure mode, gRPC clients may fail
connecting
to the server. Move the certificates out of the default location
(/usr/share/stratum/certs/ folder) in order to use insecure communication
between gRPC clients and server

### Kubernetes Networking Infrastructure Offload

* Support for Kubernetes Container Network Interface (CNI) to enable pods to
  send/receive traffic.
* Intra Node L3 Forwarding to enable pod to pod communication, on the same node,
  via CNI interfaces.
* Service Load Balancing within the node to allow multiple pods on same node to
  act as end points providing any application service.
* Bi-directional Auto Learning and Flow Pinning (a.k.a Connection Tracking),
  used with load balancing, to allow consistent end point pod selection, once it
  has been selected for the first packet.
* DNS service provided by Core DNS pods to other pods.
* Support for TLS traffic between DNS server pods and Kube API.

#### K8s Infra Components

The following are the main components of K8s Infra Offload software.

K8s Infra Manager

* The Infra Manager is deployed as a core kube-system pod along with other
  kube-system pods.
* This components acts as a gRPC server for K8s Infra Agent and receives K8s
  configurations from the Infra Agent over the gRPC channel.
* It acts as a client for the P4 Runtime Server (infrap4d) and updates the
  K8s Pipeline tables (Data Plane), over another gRPC channel, to apply K8s
  configurations.

K8s Infra Agent

* The Infra Agent is also deployed as a core kube-system pod along with other
  kube-system pods.
* It receives all CNI requests from the Calico plug-in, configures pod system
  files and adds interaces to be pods. And finally, it relays these
  configurations to the Infra Manager.
* It also acts as a K8s client for K8s API server and receives all configuration
  changes and passes them on to the Infra Manager component.
* It interacts with Infra Manager over gRPC channel to pass all the
  configurations.

K8s P4 Pipeline

* The K8s P4 pipeline is a pre-built component that can be loaded on the P4-DPDK
  dataplane.
* It comes along with the source P4 code for user to understand the packet
  processing pipeline.
* Offloading kube-proxy functionality, providing pod to pod L3 connectivity,
  local node gateway routing, load balancing & connection tracking, is all
  implemented within this pipeline.
* It exposes p4 tables that can be modified at runtime with packet processing
  rules. These rules are for managing pkt forwarding, service groups, service
  end points, etc.

### IPsec Recipe (Design Preview)

In 23.01 the IPsec Recipe is a design preview and includes a StrongSwan plugin
which implements the p4runtime and openconfig clients to configure IPsec SPD
and SAD to the target devices.

* IPsec recipe design preview is validated on Intel IPU target.
* Refer to [https://ipdk.io/documentation/Recipes/InlineIPsec/](https://ipdk.io/documentation/Recipes/InlineIPsec/)
* YANG model for IPsec SAD: [https://github.com/ipdk-io/openconfig-public/blob/master/release/models/ipsec/openconfig-ipsec-offload.yang](https://github.com/ipdk-io/openconfig-public/blob/master/release/models/ipsec/openconfig-ipsec-offload.yang)
* Reference P4 program to enable IPsec on DPDK target: [https://github.com/ipdk-io/networking-recipe/tree/main/p4src/Inline_IPsec](https://github.com/ipdk-io/networking-recipe/tree/main/p4src/Inline_IPsec)

### CI/CD

CI has been enabled for the ipdk, ipdk-io.github.io, and recipe repos.

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
