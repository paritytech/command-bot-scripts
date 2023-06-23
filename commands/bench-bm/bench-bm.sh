#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

# this is a fallback for `bench` command running on VM machine
. "$(dirname "${BASH_SOURCE[0]}")/../bench/bench.sh" "$@"
