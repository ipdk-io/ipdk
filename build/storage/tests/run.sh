#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

set -e
[ "$DEBUG" == 'true' ] && set -x

vm_file=./traffic-generator/vm.qcow2
export HTTPS_PROXY=${https_proxy}
export HTTP_PROXY=${http_proxy}
export NO_PROXY=${no_proxy}

function run_test() {
	SUDO_FOR_DOCKER="sudo"
	IS_USER_DOCKER_GROUP_MEMBER=$(groups | grep docker &> /dev/null ; echo $?)
	if [ "${IS_USER_DOCKER_GROUP_MEMBER}" == "0" ]; then
		SUDO_FOR_DOCKER=
	fi

	DO_NOT_RUN_BUILD_BASE="--scale build_base=0"
	${SUDO_FOR_DOCKER} docker-compose \
		-f ./docker-compose.yml \
		-f ./test-drivers/docker-compose.$1.yml \
		up \
		--build \
		--exit-code-from test-driver \
		${DO_NOT_RUN_BUILD_BASE}
}

function provide_hugepages() {
	if [ -d /sys/kernel/mm/hugepages/hugepages-2048kB ] ; then
		number_of_2mb_pages=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)
		required_number_of_pages=2048
		if [ "$number_of_2mb_pages" -lt "$required_number_of_pages" ] ; then
			sudo echo ${required_number_of_pages} | \
			sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
		fi
	fi
}

function provide_vm() {
	if [ ! -f "$vm_file" ]; then
		local vm_tmp_file="${vm_file}_orig"
		wget -O ${vm_tmp_file} https://download.fedoraproject.org/pub/fedora/linux/\
releases/33/Cloud/x86_64/images/Fedora-Cloud-Base-33-1.2.x86_64.qcow2
		virt-customize -a ${vm_tmp_file} \
			--root-password password:root \
			--uninstall cloud-init \
			--install fio
		 mv "${vm_tmp_file}" "${vm_file}"
	fi
}

provide_hugepages
provide_vm

test_cases=(hot-plug fio)
if [[ $# != 0 ]]; then
	run_test ${1}
else
	for i in "${test_cases[@]}"; do
		run_test ${i}
	done
fi
