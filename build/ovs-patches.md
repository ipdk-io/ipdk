---
title: "Patches to OVS"
layout: documentation
visibility: public
---

## Overview ##

The patch set into OVS enables 3 configuration paths and 1 new datapath:

 1. P4Runtime & OpenConfig using the gRPC server from Stratum.
 2. Kernel configuration such as virtual bridges, routing and tunnels.
 3. Open vSwitch configuration that can leverage both P4 and kernel constructs
 4. P4 Pipeline 'Co-processor' mode that allows the 3 configuration paths above to control a P4 pipeline that is sitting as a co-processor to the existing datapaths

## Status ##

{:class="table table=bordered"}
|Work Item|Status|Notes|
|:-----|:---:|:---|
|1. P4Runtime+OpenConfig|Integrated<br>(Requires Refactoring)|Supports PSA and PNA and is used for OVN or K8s load balancing and stateful ACLs|
|2.1. Kernel Integration - Switching|Started| VLAN, VXLAN, L2 switching, LACP, filtered through SAI|
|2.2. Kernel Integration - Routing|Started| FRR Routing, ECMP, filtered through SAI|
|3.1. OVS Integration - L1|Integrated|p4ctl for P4 and ovsctl for ports|
|3.2. OVS Integration - Mirrors|Started|Mirrors, sampling, telemetry.|
|3.3. OVS Integration - QoS|Not Started Yet|Rate Limiting|
|4. P4 pipeline co-processor|Integrated<br>(Requires Refactoring)|P4 DPDK pipeline instantiated and linked with OVS|

So, we have 3 interfaces, P4Runtime, kernel and OVS. P4Runtime and OpenConfig are working, OpenConfig is limited to ports and virtual-devices. Kernel is just starting out and will give us the OVS functionality around VLAN, VXLAN, bridges, routing, lacp, and ECMP. On top of that we have done some basic OVS integration with p4ctl and ovsctl for ports, and our roadmap is that we will enable OVS to use the kernel features as well as support mirrors, sampling, telemetry, QoS, fault management and load

The goal is to enable enough functionality to have a complete OVN dataplane that can choose to use P4 instead of OpenFlow.

## OVS Upstream ToDo List ##
Before we can post a patch set back to Open vSwitch, we have a few tasks to complete:
 - Finish the OVS feature integrations, including the kernel features like virtual bridges and tunnels like VXLAN.  Also mirrors, sampling, telemetry, QoS, fault management and load balancing, enough OVS features to enable a complete OVN dataplane.

 - Reduce the sub-modules to the bare minimum, which may require the neccasary parts in Stratum to become a standalone library instead of having to carry everything as one module

 - Better isolation of the P4 targets so that they can be re-compiled independent of P4 OVS and link dynamically. Also package in a default software P4 target with a default P4 program that provides a good amount of baseline OVS functionality.
