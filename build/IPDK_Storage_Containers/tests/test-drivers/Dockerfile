# SPDX-License-Identifier: Apache-2.0
# Copyright (c) Intel Corporation

FROM spdk

# Generic args
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY

RUN dnf install -y socat

ENTRYPOINT ["/init"]
