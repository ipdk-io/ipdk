#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
[ "$DEBUG" == 'true' ] && set -x
set -e

if [[ $# == 0 ]] ; then
    echo "Number of 2048kb pages has to be provided as the first argument"
    exit 1
fi

number_of_2mb_hugepages_folder=/sys/kernel/mm/hugepages/hugepages-2048kB
number_of_2mb_hugepages_provider=${number_of_2mb_hugepages_folder}/nr_hugepages

if [ -d ${number_of_2mb_hugepages_folder} ] ; then
    number_of_2mb_pages=$(cat ${number_of_2mb_hugepages_provider})
    required_number_of_pages=${1}
    if [ "$number_of_2mb_pages" -lt "$required_number_of_pages" ] ; then
        echo "${required_number_of_pages}" | \
        sudo tee ${number_of_2mb_hugepages_provider}
    fi
fi
