#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  cmd_runner_setup

  cmd_runner_apply_patches --setup-cleanup true

  local network="$1"

  # remove $1 and let the rest args to be passed later as "$@"
  shift

  if [ -z "$network" ];
  then
      die "the network should be provided"
  fi

  set -x
  export RUST_LOG="${RUST_LOG:-remote-ext=debug,runtime=trace}"

  # following docs https://paritytech.github.io/substrate/master/try_runtime_cli/index.html
  cargo build --release

  cargo build --release --features try-runtime

  cp "./target/release/${network}" node-try-runtime
  cp "./target/release/wbuild/${network}-runtime/${network}_runtime.wasm" runtime-try-runtime.wasm

  ./node-try-runtime \
    try-runtime \
    --runtime runtime-try-runtime.wasm \
    -lruntime=debug \
    on-runtime-upgrade \
    live --uri "wss://${network}-try-runtime-node.parity-chains.parity.io:443" \
    "$@"
}

main "$@"
