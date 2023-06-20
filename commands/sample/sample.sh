#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

get_arg optional --input "$@"
input="${out:-"no input"}"


echo "$input"
