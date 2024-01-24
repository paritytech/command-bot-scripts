#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit
shopt -s globstar

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

get_arg optional --pallet "$@"
PALLET="${out:-""}"

if [[ ! -z "$PALLET" ]]; then
  . "$(dirname "${BASH_SOURCE[0]}")/lib/bench-all-pallet.sh" "$@"
else
  . "$(dirname "${BASH_SOURCE[0]}")/../bench/bench.sh" --subcommand=all "$@"
fi

