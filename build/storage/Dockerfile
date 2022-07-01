# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# NOTICE: THIS FILE HAS BEEN MODIFIED BY INTEL CORPORATION UNDER COMPLIANCE
# WITH THE APACHE 2.0 LICENSE FROM THE ORIGINAL WORK
#
################################################################################
# build_base
#
# This image is used to provide environment for spdk build and get it in the
# form of spdk packages
################################################################################
FROM fedora:36 AS base

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG SPDK_VERSION

RUN dnf install -y git
COPY spdk/ /spdk
RUN mkdir /spdk-rpm
COPY core/build_base/pre-install /install
RUN chmod +x /install
RUN /install

################################################################################
# spdk
#
# Contains installed SPDK from build_base rpm packages.
# Does not contain dependencies required to build SPDK
################################################################################
FROM fedora:36 AS spdk

LABEL maintainer=spdk.io

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

# Copy SPDK's RPMs built during pre-install step.
# This allows to reduce final image size since we won't have any dependencies
# which are only required to perform build.
RUN mkdir /spdk-rpm
COPY --from=base /spdk-rpm/*.rpm /spdk-rpm/
COPY --from=base /spdk-rpm/fio /spdk-rpm/

RUN dnf install -y python python3-pip
RUN python -m pip install grpcio grpcio-tools

# Wrap up the image
COPY core/build_base/post-install /install
RUN chmod +x /install
RUN /install


################################################################################
# spdk-app
#
# This image in addition to installed SPDK binaries contains a script run at
# container boot.
# This script runs SPDK service.
################################################################################
FROM spdk as spdk-app

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

RUN dnf install -y socat
COPY core/spdk-app/init /init

ENTRYPOINT ["/init"]


################################################################################
# storage-target
#
# This image should be place on a dedicated machine and responsible for exposing
# ideal storage target(SPDK Malloc bdev) over NVMe/TCP
# Configuration is performed by means of SPDK Json rpc.
################################################################################
FROM spdk-app AS storage-target

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

################################################################################
# ipu-storage-container
#
# This image is placed on IPU and exposing storage-target NVMe/TCP devices
# It is responsible for creation of vhost virtio-blk devices and exposing them
# to hosts(KVM or physical ones)
################################################################################
FROM spdk as ipu-storage-container

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

RUN dnf install -y socat
RUN pip install pyyaml

COPY core/ipu-storage-container/init /init
COPY --from=spdk-app /init /init_spdk

ENTRYPOINT [ "/init" ]


################################################################################
# host-target
#
# This image is responsible for running fio payload over different pci devices.
# It has to be placed into host(a vm for KVM case or physical host for IPU case)
# It uses gRPC to expose this service.
################################################################################
FROM fedora:36 AS host-target

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

RUN dnf install -y python fio python3-pip
RUN python -m pip install grpcio grpcio-tools grpcio-reflection

COPY core/host-target/init /init
COPY core/host-target/*.py /
COPY core/host-target/host_target.proto /host_target.proto

RUN python -m grpc_tools.protoc -I/ --python_out=. --grpc_python_out=/ \
    /host_target.proto

ENTRYPOINT [ "/init" ]

################################################################################
# ipdk-unit-tests
################################################################################
FROM fedora:36 AS ipdk-unit-tests

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

RUN dnf install -y python fio python3-pip
RUN python -m pip install grpcio-reflection pyfakefs

COPY tests/ut/host-target /host-target/tests
COPY --from=host-target fio_runner.py /host-target/src/
COPY --from=host-target pci_devices.py /host-target/src/
COPY --from=host-target device_exerciser.py /host-target/src/
COPY --from=host-target host_target_main.py /host-target/src/
COPY --from=host-target host_target_grpc_server.py /host-target/src/
COPY --from=host-target host_target_*pb2.py /host-target/generated/
COPY --from=host-target host_target_*pb2_grpc.py /host-target/generated/

COPY tests/ut/run_all_unit_tests.sh /

ENV PYTHONPATH=/host-target/src:/host-target/generated

ENTRYPOINT [ "/run_all_unit_tests.sh" ]
