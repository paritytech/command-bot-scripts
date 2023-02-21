#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

echo $(pwd)
echo ls -lsa
cd ../
echo ls -lsa
cd ../bench
# this is a fallback for `bench` command running on BM3 machine
. "$(dirname "${BASH_SOURCE[0]}")../bench/bench.sh" "$@"
