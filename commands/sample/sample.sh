#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"

get_arg optional --input "$@"
input="${out:-"no input"}"

echo "$input"
