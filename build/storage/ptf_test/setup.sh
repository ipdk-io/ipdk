#!/bin/bash

branch='feat-add-ptf-setup-tests'
git_url='https://github.com/intelfisz/ipdk.git'
ptf_url='https://github.com/p4lang/ptf.git'

current_dir=$(pwd)
storage_path="$current_dir/IPDK_workspace/ipdk/build/storage/"

mkdir -p "IPDK_workspace"
cd "IPDK_workspace" && git clone --branch "$branch" "$git_url"
cd "$storage_path" && git clone "$ptf_url"
cd "$storage_path" && git submodule update --init --recursive --force
cd && mkdir -p "IPDK_workspace/SHARE"
