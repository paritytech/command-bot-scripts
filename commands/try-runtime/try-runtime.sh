#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  cmd_runner_setup

  cmd_runner_apply_patches --setup-cleanup true

  local chain="${ARGS[chain]}"
  local uri="${ARGS[uri]}"

  if [ -z "$chain" ] || [ -z "$uri" ]; then
    # this is probably redundant, as the validation should be performed on bot's side
    die "chain and uri arguments should be provided"
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
    --chain="$chain"
    --execution=Wasm
    --no-spec-check-panic
    on-runtime-upgrade
    live
    --uri="$uri"
  )

  set -x
  export RUST_LOG="${RUST_LOG:-remote-ext=debug,runtime=trace}"
  cargo "${preset_args[@]}"
}

main
