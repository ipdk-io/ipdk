# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# NOTICE: THIS FILE HAS BEEN MODIFIED BY INTEL CORPORATION UNDER COMPLIANCE
# WITH THE APACHE 2.0 LICENSE FROM THE ORIGINAL WORK
#

FROM fedora:33 AS base

# Generic args
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY

RUN dnf install -y git
RUN git clone https://github.com/spdk/spdk.git
RUN tar -czf spdk.tar.gz --exclude='docker/*' -C ./spdk .
COPY pre-install /install
RUN chmod +x /install
RUN /install

# We are doing a multi-stage build here. This means that previous image,
# base, is going to end up as an intermediate one, untagged, <none> - this
# image can be then manually removed (--force-rm doesn't work here. Go
# figure).
FROM fedora:33 AS spdk

LABEL maintainer=spdk.io

# Proxy configuration must be set for each build separately...
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY

# Copy SPDK's RPMs built during pre-install step.
COPY --from=base /tmp/*.rpm /tmp/
COPY --from=base /tmp/fio /tmp/
# Wrap up the image
COPY post-install /install
RUN chmod +x /install
RUN /install
