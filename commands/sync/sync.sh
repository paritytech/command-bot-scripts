#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  # setup.
  cmd_runner_setup

  get_arg required --chain "$@"
  local chain="${out:-""}"

  get_arg required --type "$@"
  local type="${out:-""}"

  set -x
  export RUST_LOG="${RUST_LOG:-remote-ext=debug,runtime=trace}"

  cargo build --release

  cp "./target/release/polkadot" ./polkadot-bin
  ls -lsa
  ./polkadot-bin --sync="$type" --chain="$chain"
}

main "$@"
