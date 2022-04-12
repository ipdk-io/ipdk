#!/usr/bin/env bash
#
# Simple script to find all bash scripts and run shellcheck on them
#

set -eu

is_bash() {
    [[ $1 == *.sh ]] && return 0
    [[ $1 == */bash-completion/* ]] && return 0
    [[ $(file -b --mime-type "$1") == text/x-shellscript ]] && return 0
    return 1
}

while IFS= read -r -d $'' file; do
    if is_bash "$file"; then
        shellcheck -x -W0 -s bash "$file" || continue
    fi
done < <(find . -type f \! -path "./.git/*" -print0)
