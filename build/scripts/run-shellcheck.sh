#!/usr/bin/env bash
#
# Simple script to find all bash scripts and run shellcheck on them
#

set -euxo pipefail

is_bash() {
    [[ $1 == *.sh ]] && return 0
    [[ $1 == */bash-completion/* ]] && return 0
    [[ $(file -b --mime-type "$1") == text/x-shellscript ]] && return 0
    return 1
}

is_excluded_from_check() {
    [[ $1 == */spdk/* ]] && return 0

    return 1
}

while IFS= read -r -d $'' file; do
    if ! is_excluded_from_check "$file" && is_bash "$file" ; then
        shellcheck -x -W0 -s bash "$file"
        rc=$?
        if [ "${rc}" -eq 0 ]
        then
            continue
        else
            exit 1
        fi
    fi
done < <(find . -type f \! -path "./.git/*" -print0)
