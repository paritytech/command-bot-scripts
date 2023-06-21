#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  cmd_runner_setup

  cmd_runner_apply_patches --setup-cleanup true

  get_arg required --chain "$@"
  local chain="${out:-""}"

  get_arg required --chain_node "$@"
  local chain_node="${out:-""}"

  get_arg optional --output_path "$@"
  local output_path="${out:-"."}"

  set -x
  export RUST_LOG="${RUST_LOG:-remote-ext=debug,runtime=trace}"

  # following docs https://paritytech.github.io/substrate/master/try_runtime_cli/index.html
  cargo build --release

  cargo build --release --features try-runtime

  cp "$output_path/target/release/${chain_node}" node-try-runtime
  cp "$output_path/target/release/wbuild/${chain}-runtime/${chain}_runtime.wasm" runtime-try-runtime.wasm

  ./node-try-runtime \
    try-runtime \
    --runtime runtime-try-runtime.wasm \
    -lruntime=debug \
    on-runtime-upgrade \
    live --uri "wss://${chain}-try-runtime-node.parity-chains.parity.io:443"
}

main "$@"
