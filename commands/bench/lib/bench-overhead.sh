#!/bin/bash

THIS_DIR=$(dirname "${BASH_SOURCE[0]}")
. "$THIS_DIR/../../cmd_runner.sh"
. "$THIS_DIR/../../utils.sh"

bench_overhead_common_args=(
  --
  benchmark
  overhead
  --execution=wasm
  --wasm-execution=compiled
  --warmup=10
  --repeat=100
)
bench_overhead() {
  local args
  case "$target_dir" in
    substrate)
      args=(
        "${bench_overhead_common_args[@]}"
        --header=./HEADER-APACHE2
        --weight-path="./frame/support/src/weights"
        --chain="dev"
      )
    ;;
    polkadot)
      local runtime="$2"
      args=(
        "${bench_overhead_common_args[@]}"
        --header=./file_header.txt
        --weight-path="./runtime/$runtime/constants/src/weights"
        --chain="$runtime-dev"
      )
    ;;
    cumulus)
      local chain_type="$2"
      local runtime="$3"

      args=(
        --bin=polkadot-parachain
        "${bench_overhead_common_args[@]}"
        --header=./file_header.txt
        --weight-path="./cumulus/parachains/runtimes/$chain_type/$runtime/src/weights"
        --chain="$runtime"
      )
    ;;
    trappist)
      local runtime="$2"
      args=(
        "${bench_overhead_common_args[@]}"
        --header=./templates/file_header.txt
        --weight-path="./runtime/$runtime/src/weights"
        --chain="$runtime-dev"
      )
    ;;
    *)
      die "Repository $target_dir is not supported in bench_overhead"
    ;;
  esac

  cargo_run "${args[@]}"
}

bench_overhead "$@"
