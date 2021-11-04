#!/bin/bash
#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

set -e

get_os_ver_details()
{
  if [ -f /etc/os-release ]; then
      # freedesktop.org and systemd
      . /etc/os-release
      OS=$NAME
      VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
      # linuxbase.org
      OS=$(lsb_release -si)
      VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
      # For some versions of Debian/Ubuntu without lsb_release command
      . /etc/lsb-release
      OS=$DISTRIB_ID
      VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
      # Older Debian/Ubuntu/etc.
      OS=Debian
      VER=$(cat /etc/debian_version)
  else
      # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
      OS=$(uname -s)
      VER=$(uname -r)
  fi
}

get_num_cores()
{
   nproc_exist=$(which nproc)
   if [ ! -z "$nproc_exist" ];
   then
       NUM_CORES=$(nproc --all)
       echo "Num cores on a system: $NUM_CORES"
       if [ "$NUM_CORES" -gt 4 ]
       then
           NUM_THREADS=$(($NUM_CORES / 4))
           NUM_THREADS=-j$NUM_THREADS
       fi
else
    NUM_CORES=""
fi
}
