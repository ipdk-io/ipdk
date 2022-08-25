#!/bin/bash

test_case_names=(
  "test_connection"
  "test_setup"
  "test_containers_deploy"
  "test_docker"
)

path_to_ptf=$(find "$HOME" -name ptf | head -n 1)
path_to_tests=$(find "$HOME" -name ptf_test | head -n 1)

cd "$path_to_ptf"
for i in "${test_case_names[@]}"; do
   sudo ./ptf --test-dir "$path_to_tests"/setup_tests "$i" --pypath /usr/lib/python3.9/ --platform=dummy
done
cd "$path_to_tests"
