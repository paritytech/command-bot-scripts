#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

echo "${ARGS[input]}"
