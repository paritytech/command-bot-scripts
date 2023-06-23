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

  local chain="$1"
  local chain_node=""

  case "$chain" in
      polkadot|kusama|westend|rococo)
        chain_node="polkadot"
      ;;
      trappist)
        chain_node="trappist-node"
      ;;
      *)
        die "Invalid chain $chain"
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
    live --uri "wss://rococo-${chain}-try-runtime-node.parity-chains.parity.io:443"
}

main "$@"
