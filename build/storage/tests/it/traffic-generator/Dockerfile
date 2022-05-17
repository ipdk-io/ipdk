# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# NOTICE: THIS FILE HAS BEEN MODIFIED BY INTEL CORPORATION UNDER COMPLIANCE
# WITH THE APACHE 2.0 LICENSE FROM THE ORIGINAL WORK
#
FROM fedora:33 as traffic-generator-base

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY

RUN dnf install -y wget
RUN dnf install -y libguestfs-tools-c

COPY scripts/* /scripts/
COPY scripts/vm/* /scripts/vm/
RUN WITHOUT_HOST_TARGET=true /scripts/vm/prepare_vm.sh /

FROM fedora:33 AS traffic-generator

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY

RUN dnf install -y qemu-kvm
COPY tests/it/traffic-generator/init /init
RUN chmod +x /init
COPY --from=traffic-generator-base /vm.qcow2 /vm.qcow2


ENTRYPOINT ["/init"]
