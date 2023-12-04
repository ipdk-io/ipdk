#!/bin/bash
#Copyright (C) 2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

usage() {
    echo ""
    echo "Usage:"
    echo ":generate_tls_certs.sh -w|--workdir -h|--help"
    echo ""
    echo "  -w|--workdir: Working directory. [Default: /root]"
    echo "  -h|--help: Displays help"
    echo ""
}

# Parse command-line options.
SHORTOPTS=h,w:
LONGOPTS=help,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR="/root"

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
      usage
      exit 1 ;;
    -w|--workdir)
        WORKING_DIR="${2}"
        shift 2 ;;
    --)
        shift
        break ;;
    *)
        echo "Internal error!"
        exit 1 ;;
    esac
done

# Display argument data after parsing commandline arguments
echo ""
echo "WORKING_DIR: ${WORKING_DIR}"

echo "Generating TLS Certificates..."
CERTS_DIR_LOCATION=/usr/share/stratum/certs/
#mkdir -p "${CERTS_DIR_LOCATION}"
COMMON_NAME=localhost "${WORKING_DIR}"/networking-recipe/tools/tls/generate-certs.sh
status=$?
if [ "${status}" -eq 0 ]; then
   echo "Deleting old installed certificates"
   rm -rf $CERTS_DIR_LOCATION
   cp -pr "${WORKING_DIR}"/networking-recipe/tools/tls/certs/ $CERTS_DIR_LOCATION
   echo "Certificates generated and installed successfully in " $CERTS_DIR_LOCATION
else
   echo "Failed to generate certificates to enable TLS mode"
fi
