# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# NOTICE: THIS FILE HAS BEEN MODIFIED BY INTEL CORPORATION UNDER COMPLIANCE
# WITH THE APACHE 2.0 LICENSE FROM THE ORIGINAL WORK
#
# hadolint ignore=DL3006
FROM spdk-app AS test-driver

# Generic args
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
 
RUN dnf install -y socat grpc-cli jq && dnf clean all

COPY tests/it/test-drivers/test-helpers /test-helpers
COPY scripts/ /scripts

ENTRYPOINT ["/init"]
