# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# NOTICE: THIS FILE HAS BEEN MODIFIED BY INTEL CORPORATION UNDER COMPLIANCE
# WITH THE APACHE 2.0 LICENSE FROM THE ORIGINAL WORK
#
FROM fedora:36 as base
ARG DRIVE_TO_BOOT=/vm.qcow2
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ENV DRIVE_TO_BOOT=$DRIVE_TO_BOOT
ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY

FROM base as traffic-generator-base

RUN dnf install -y wget
RUN dnf install -y libguestfs-tools-c

COPY scripts/vm/prepare_vm.sh /scripts/vm/prepare_vm.sh
RUN WITHOUT_HOST_TARGET=true /scripts/vm/prepare_vm.sh $DRIVE_TO_BOOT

FROM base AS traffic-generator

RUN dnf install -y qemu-kvm
RUN dnf install -y iproute dnsmasq
COPY tests/it/traffic-generator/init /init
COPY --from=traffic-generator-base $DRIVE_TO_BOOT $DRIVE_TO_BOOT
COPY /scripts /scripts
ENV SHARED_VOLUME=/ipdk-shared
ENV UNIX_SERIAL=vm_socket
ENTRYPOINT ["/init"]
