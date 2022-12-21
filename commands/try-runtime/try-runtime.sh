#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

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

  local preset_args=(
    run
    # Requirement: always run the command in release mode.
    # See https://github.com/paritytech/command-bot/issues/26#issue-1049555966
    --release
    # "--quiet" should be kept so that the output doesn't get polluted
    # with a bunch of compilation stuff
    --quiet
    --features=try-runtime
    try-runtime
    --chain="${network}-dev"
    --execution=Wasm
    --no-spec-check-panic
    on-runtime-upgrade
    live
    --uri wss://${network}-try-runtime-node.parity-chains.parity.io:443
  )

  set -x
  export RUST_LOG="${RUST_LOG:-remote-ext=debug,runtime=trace}"
  cargo "${preset_args[@]}" "$@"
}

main "$@"
