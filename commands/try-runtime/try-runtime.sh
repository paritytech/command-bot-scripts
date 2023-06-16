#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

current_folder="$(basename "$PWD")"

get_arg optional --repo "$@"
repository="${out:=$current_folder}"

main() {
  cmd_runner_setup

  cmd_runner_apply_patches --setup-cleanup true

  local runtime="$1"
  local runtime_node=""

  case "$runtime" in
      polkadot|kusama|westend|rococo)
        runtime_node="polkadot"
      ;;
      trappist)
        runtime_node="trappist-node"
      ;;
      *)
        die "Invalid runtime $runtime"
      ;;
    esac

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
    live --uri "wss://${runtime}-try-runtime-node.parity-chains.parity.io:443"
}

main
