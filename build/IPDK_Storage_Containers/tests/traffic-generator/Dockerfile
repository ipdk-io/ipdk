# SPDX-License-Identifier: Apache-2.0
# Copyright (c) Intel Corporation
#
# NOTICE: THIS FILE HAS BEEN MODIFIED BY INTEL CORPORATION UNDER COMPLIANCE
# WITH THE APACHE 2.0 LICENSE FROM THE ORIGINAL WORK
#

FROM spdk

# Generic args
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY


COPY vm.qcow2 /vm.qcow2
RUN dnf install -y qemu-kvm
COPY init /init
RUN chmod +x /init

ENTRYPOINT ["/init"]
