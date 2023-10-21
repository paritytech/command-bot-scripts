#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  cmd_runner_setup

  get_arg required --chain "$@"
  local chain="${out:-""}"

  get_arg required --chain_node "$@"
  local chain_node="${out:-""}"

  get_arg optional --live_uri "$@"
  local live_uri="${out:-"$chain"}"

  set -x
  export RUST_LOG="${RUST_LOG:-remote-ext=debug,runtime=trace}"

  # following docs https://paritytech.github.io/substrate/master/try_runtime_cli/index.html
  cargo build --release

  cargo build --release --features try-runtime

  cp "./target/release/${chain_node}" node-try-runtime
  cp "./target/release/wbuild/${chain}-runtime/${chain}_runtime.wasm" runtime-try-runtime.wasm

  ./node-try-runtime \
    try-runtime \
    --runtime runtime-try-runtime.wasm \
    -lruntime=debug \
    on-runtime-upgrade \
    live --uri "wss://${live_uri}-try-runtime-node.parity-chains.parity.io:443"
}

main "$@"
