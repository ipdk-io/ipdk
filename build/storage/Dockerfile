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

RUN dnf install -y git && dnf clean all
COPY spdk/ /spdk
RUN mkdir /spdk-rpm
COPY core/build_base/pre-install /install
RUN chmod +x /install && /install

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

# hadolint ignore=DL3013
RUN dnf install -y python python3-pip && dnf clean all && \
    python -m pip install --no-cache-dir grpcio grpcio-tools protobuf==3.20.2

# Wrap up the image
COPY core/build_base/post-install /install
RUN chmod +x /install && /install


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

RUN dnf install -y socat && dnf clean all
COPY core/spdk-app/init /init

ENTRYPOINT ["/init"]


################################################################################
# storage-target
#
# This image should be placed on a dedicated machine and responsible for
# exposing ideal storage target (SPDK Malloc bdev) over NVMe/TCP
# Configuration is performed by means of SPDK Json rpc.
################################################################################
FROM spdk-app AS storage-target

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

################################################################################
# ipu-storage-container
#
# This image is placed on IPU and attaching to storage-target NVMe/TCP devices.
# It is responsible for creation of vhost virtio-blk devices and exposing them
# to hosts(KVM or physical ones)
################################################################################
FROM spdk as ipu-storage-container

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

# hadolint ignore=DL3013
RUN dnf install -y socat && dnf clean all && pip install --no-cache-dir pyyaml

COPY core/ipu-storage-container/init /init
COPY --from=spdk-app /init /init_spdk

ENTRYPOINT [ "/init" ]


################################################################################
# host-target
#
# This image is responsible for running fio payload over different pci devices.
# It has to be placed into host (a vm for KVM case or physical host for IPU
# case). It uses gRPC to expose this service.
################################################################################
FROM fedora:36 AS host-target

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

COPY core/host-target/requirements.txt /
# hadolint ignore=DL3013
RUN dnf install -y python fio python3-pip && dnf clean all && \
    python -m pip install --no-cache-dir -r /requirements.txt

COPY core/host-target/init /init
COPY core/host-target/*.py /
COPY core/host-target/host_target.proto /host_target.proto

RUN python -m grpc_tools.protoc -I/ --python_out=. --grpc_python_out=/ \
    /host_target.proto

ENV CUSTOMIZATION_DIR_IN_CONTAINER=/customizations
COPY core/host-target/customizations $CUSTOMIZATION_DIR_IN_CONTAINER

ENTRYPOINT [ "/init" ]

################################################################################
# traffic-generator
#
# Runs qemu instance with host-target on board.
# Represents a virtualized host.
################################################################################
FROM fedora:36 as traffic-generator-env-vars
ARG DRIVE_TO_BOOT=/vm.qcow2
ARG HOST_TARGET_TAR=/host-target.tar
ARG HOST_TARGET_SERVICE_PORT_IN_VM=50051
ARG HOST_TARGET_SERVICE_PORT=50051
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ENV DRIVE_TO_BOOT=$DRIVE_TO_BOOT
ENV HOST_TARGET_SERVICE_PORT=$HOST_TARGET_SERVICE_PORT
ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY

FROM traffic-generator-env-vars as traffic-generator-base

RUN dnf install -y wget && dnf install -y libguestfs-tools-c && dnf clean all

COPY scripts/vm/prepare_vm.sh /scripts/vm/prepare_vm.sh
COPY scripts/run_host_target_container.sh /scripts/run_host_target_container.sh
COPY scripts/run_container.sh /scripts/run_container.sh
COPY scripts/host-target.tar $HOST_TARGET_TAR
RUN /scripts/vm/prepare_vm.sh

FROM traffic-generator-env-vars AS traffic-generator

RUN dnf install -y git glib2-devel libfdt-devel pixman-devel zlib-devel bzip2 \
    ninja-build python3 make gcc diffutils && dnf clean all
RUN git clone https://github.com/oracle/qemu /qemu-orcl
WORKDIR /qemu-orcl
RUN git checkout 46bb039c31e92ae84cf7fe1f64119c1a78e0d101 && \
    git submodule update --init --recursive
RUN ./configure --enable-multiprocess && make -j && make install
WORKDIR /
RUN rm -rf ./qemu-orcl
COPY tests/it/traffic-generator/init /init
COPY --from=traffic-generator-base $DRIVE_TO_BOOT $DRIVE_TO_BOOT
COPY /scripts /scripts
ENV SHARED_VOLUME=/ipdk-shared
ENV UNIX_SERIAL=vm_socket
ENTRYPOINT ["/init"]


################################################################################
# cmd-sender
#
# Contains all required tools to send control commands to other containers.
################################################################################
FROM spdk-app AS cmd-sender-base
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

RUN dnf install -y socat grpc-cli jq && dnf clean all

COPY tests/it/test-drivers/test-helpers /test-helpers
COPY scripts/ /scripts

FROM cmd-sender-base AS cmd-sender
RUN echo "source /scripts/disk_infrastructure.sh" >> ~/.bashrc
ENTRYPOINT ["/bin/bash"]


################################################################################
# test-driver
#
# Issues all control commands for other containers in tests.
################################################################################
FROM cmd-sender-base AS test-driver

ENTRYPOINT ["/init"]


################################################################################
# ipdk-unit-tests
################################################################################
FROM fedora:36 AS ipdk-unit-tests

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

# hadolint ignore=DL3013
RUN dnf install -y python fio python3-pip && dnf clean all && python -m pip install --no-cache-dir grpcio-reflection pyfakefs

COPY tests/ut/host-target /host-target/tests
COPY --from=host-target fio_runner.py /host-target/src/
COPY --from=host-target fio_args.py /host-target/src/
COPY --from=host-target pci_devices.py /host-target/src/
COPY --from=host-target device_exerciser_kvm.py /host-target/src/
COPY --from=host-target device_exerciser_if.py /host-target/src/
COPY --from=host-target device_exerciser_customization.py /host-target/src/
COPY --from=host-target host_target_main.py /host-target/src/
COPY --from=host-target host_target_grpc_server.py /host-target/src/
COPY --from=host-target volume.py /host-target/src/
COPY --from=host-target host_target_*pb2.py /host-target/generated/
COPY --from=host-target host_target_*pb2_grpc.py /host-target/generated/

COPY tests/ut/run_all_unit_tests.sh /

ENV PYTHONPATH=/host-target/src:/host-target/generated

ENTRYPOINT [ "/run_all_unit_tests.sh" ]
