# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# NOTICE: THIS FILE HAS BEEN MODIFIED BY INTEL CORPORATION UNDER COMPLIANCE
# WITH THE APACHE 2.0 LICENSE FROM THE ORIGINAL WORK
#
################################################################################
# base
#
# This image is used to provide environment for spdk build and get it in the
# form of spdk packages
################################################################################
FROM fedora:36 AS base

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG SPDK_VERSION
ARG SPDK_TARGET_ARCH

COPY spdk/ /spdk
RUN rm -rf /spdk/build && \
    mkdir /spdk-rpm && \
    dnf install -y rpm-build && dnf clean all && \
    /spdk/scripts/pkgdep.sh -d
RUN DEPS="no" /spdk/rpmbuild/rpm.sh --with-vfio-user --with-virtio \
        --with-sma --with-crypto \
        --target-arch=${SPDK_TARGET_ARCH} && \
    mv ~/rpmbuild/rpm/x86_64/*.rpm /spdk-rpm/

################################################################################
# spdk
#
# Contains installed SPDK from base rpm packages.
# Does not contain dependencies required to build SPDK
################################################################################
FROM fedora:36 AS spdk

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

# Copy SPDK's RPMs built during pre-install step.
# This allows to reduce final image size since we won't have any dependencies
# which are only required to perform build.
RUN mkdir /spdk-rpm
COPY --from=base /spdk-rpm/*.rpm /spdk-rpm/

# hadolint ignore=DL3013
RUN dnf install -y python python3-pip /spdk-rpm/*.rpm && dnf clean all && \
    python -m pip install --no-cache-dir \
    grpcio==1.51.1 grpcio-tools==1.48.2 protobuf==3.20.2 setuptools==65.5.1 && \
    rm -f /tmp/*.rpm && \
    for f in /usr/local/bin/*; do ln -sf "$f" /usr/bin ; done && \
    ln -s /usr/libexec/spdk/scripts/rpc.py /usr/bin && \
    ln -s /usr/libexec/spdk/scripts/rpc_http_proxy.py /usr/bin && \
    ln -s /usr/libexec/spdk/scripts/setup.sh /usr/bin && \
    ln -s /usr/libexec/spdk/include/spdk /usr/include && \
    ln -s /usr/libexec/spdk/scripts/ /usr && \
    ln -s /usr/libexec/spdk/scripts/sma.py /usr/bin && \
    ln -s /usr/libexec/spdk/scripts/sma-client.py /usr/bin


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

# hadolint ignore=DL3013
WORKDIR /root
COPY core/host-target/requirements.txt .
RUN dnf install -y python fio python3-pip && dnf clean all && \
    python -m pip install --no-cache-dir -r ./requirements.txt
COPY core/host-target ./
COPY core/host-target/host_target.proto ./host_target.proto

RUN python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. \
    ./host_target.proto

ENV CUSTOMIZATION_DIR_IN_CONTAINER=./customizations
COPY core/host-target/customizations $CUSTOMIZATION_DIR_IN_CONTAINER

ENTRYPOINT [ "./init" ]

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
    ninja-build python3 make gcc diffutils libaio-devel numactl-devel && \
    dnf clean all
COPY tests/it/traffic-generator/init /init
COPY --from=traffic-generator-base $DRIVE_TO_BOOT $DRIVE_TO_BOOT
COPY /scripts /scripts
COPY /spdk/test/common/config/pkgdep/git /spdk/test/common/config/pkgdep/git
RUN /scripts/vm/install_qemu.sh
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

COPY tests/it/test-drivers/test-max-qos /test-max-qos

ENTRYPOINT ["/init"]


################################################################################
# ipdk-unit-tests
################################################################################
FROM fedora:36 AS ipdk-unit-tests

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

# hadolint ignore=DL3013
RUN dnf install -y python fio python3-pip && dnf clean all && python -m pip install \
    --no-cache-dir protobuf==3.20.2 grpcio-reflection pyfakefs

COPY tests/ut/host-target /host-target/tests
COPY --from=host-target /root /host-target/src/
COPY --from=host-target /root/host_target_*pb2.py /host-target/generated/
COPY --from=host-target /root/host_target_*pb2_grpc.py /host-target/generated/

COPY tests/ut/run_all_unit_tests.sh /

ENV PYTHONPATH=/host-target/src:/host-target/generated

ENTRYPOINT [ "/run_all_unit_tests.sh" ]
