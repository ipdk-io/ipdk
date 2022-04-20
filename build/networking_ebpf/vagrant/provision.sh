#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#
# Version 0.1.0

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

apt-get update

apt-get install -y apt-utils \
        git \
        meson \
        cmake \
        libtool \
        clang \
        gcc \
        g++ \
        autoconf \
        automake \
        autoconf-archive \
        libconfig++-dev \
        libgc-dev \
        unifdef \
        libffi-dev \
        libboost-iostreams-dev \
        libboost-graph-dev \
        llvm \
        pkg-config \
        flex libfl-dev \
        zlib1g-dev \
        iproute2 \
        net-tools \
        iputils-arping \
        iputils-ping \
        iputils-tracepath \
        python \
        pip \
        bison \
        python3-setuptools \
        python3-pip \
        python3-wheel \
        python3-cffi \
        libedit-dev \
        libgmp-dev \
        libexpat1-dev \
        libboost-dev \
        google-perftools \
        curl \
        connect-proxy \
        coreutils \
        sudo \
        make \
        cloud-image-utils \
        telnet \
        qemu-kvm \
	libelf-dev \
	libjansson-dev \
	psmisc

pip install --upgrade pip
pip install grpcio \
            ovspy \
            protobuf \
            p4runtime \
            pyelftools \
            scapy \
            six \
	    pyenv

# Install docker
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get -y install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
sudo groupadd docker
sudo usermod -aG docker vagrant

# Install golang
if [ ! -f go1.18.linux-amd64.tar.gz ] ; then
    curl -OL https://golang.org/dl/go1.18.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.18.linux-amd64.tar.gz
fi
echo "PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
if [ ! -d ~/go ] ; then
	mkdir -p ~/go
fi
if [ ! -d ~/go/src ] ; then
	mkdir -p ~/go/src/
fi
if [ ! -d ~/go/src/ipdk-plugin ] ; then
    pushd ~/go/src || exit
    git clone https://github.com/mestery/ipdk-plugin
    popd || exit
fi
pushd ~/go/src/ipdk-plugin || exit
go get
go build
popd || exit
