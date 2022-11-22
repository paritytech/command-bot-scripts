#!/bin/bash

# This file is separated to simplify testing the final pure command output

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/cmd_runner.sh"

cargo_run_benchmarks="cargo run --locked --quiet --profile=production"

echo "Repo: $REPOSITORY"

cargo_run() {
  echo "Running $cargo_run_benchmarks" "${cargo_args[@]}"

  $cargo_run_benchmarks "${cargo_args[@]}"
}

bench_pallet_common_args=(
  --
  benchmark
  pallet
  --steps=50
  --repeat=20
  --extrinsic="*"
  --execution=wasm
  --wasm-execution=compiled
  --heap-pages=4096
  --json-file="${ARTIFACTS_DIR}/bench.json"
)
bench_pallet() {
  local kind="${ARGS[kind]}"
  local runtime="${ARGS[runtime]}"

  local cargo_args
  case "$REPOSITORY" in
    substrate)
      local pallet="${ARGS[pallet]}"

      cargo_args=(
        --features=runtime-benchmarks
        --manifest-path=bin/node/cli/Cargo.toml
        "${bench_pallet_common_args[@]}"
        --pallet="$pallet"
        --chain="$runtime"
      )

      case "$kind" in
        pallet)
          # Translates e.g. "pallet_foo::bar" to "pallet_foo_bar"
          local output_dir="${pallet//::/_}"

          # Substrate benchmarks are output to the "frame" directory but they aren't
          # named exactly after the $pallet argument. For example:
          # - When $pallet == pallet_balances, the output folder is frame/balances
          # - When $pallet == frame_benchmarking, the output folder is frame/benchmarking
          # The common pattern we infer from those examples is that we should remove
          # the prefix
          if [[ "$output_dir" =~ ^[A-Za-z]*[^A-Za-z](.*)$ ]]; then
            output_dir="${BASH_REMATCH[1]}"
          fi

          # We also need to translate '_' to '-' due to the folders' naming
          # conventions
          output_dir="${output_dir//_/-}"

          cargo_args+=(
            --header="./HEADER-APACHE2"
            --output="./frame/$output_dir/src/weights.rs"
            --template=./.maintain/frame-weight-template.hbs
          )
        ;;
        *)
          die "Kind $kind is not supported for $REPOSITORY in bench_pallet"
        ;;
      esac
    ;;
    polkadot)
      local pallet="${ARGS[pallet]}"

      cargo_args=(
        --features=runtime-benchmarks
        "${bench_pallet_common_args[@]}"
        --pallet="$pallet"
        --chain="$runtime"
      )

      local runtime_dir
      if [ "$runtime" == dev ]; then
        runtime_dir=polkadot
      elif [[ "$runtime" =~ ^(.*)-dev$  ]]; then
        runtime_dir="${BASH_REMATCH[1]}"
      else
        die "Could not infer weights directory from $runtime"
      fi
      local weights_dir="./runtime/${runtime_dir}/src/weights"

      case "$kind" in
        runtime)
          cargo_args+=(
            --header=./file_header.txt
            --output="${weights_dir}/"
          )
        ;;
        xcm)
          cargo_args+=(
            --header=./file_header.txt
            --template=./xcm/pallet-xcm-benchmarks/template.hbs
            --output="${weights_dir}/xcm/"
          )
        ;;
        *)
          die "Kind $kind is not supported for $REPOSITORY in bench_pallet"
        ;;
      esac
    ;;
    cumulus)
      local chain_type="${ARGS[type]}"
      local pallet="${ARGS[pallet]}"

      cargo_args=(
        --bin=polkadot-parachain
        --features=runtime-benchmarks
        "${bench_pallet_common_args[@]}"
        --pallet="$pallet"
        --chain="${runtime}-dev"
        --header=./file_header.txt
      )

      case "$kind" in
        pallet)
          cargo_args+=(
            --output="./parachains/runtimes/$chain_type/$runtime/src/weights/"
          )
        ;;
        xcm)
          mkdir -p "./parachains/runtimes/$chain_type/$runtime/src/weights/xcm"
          cargo_args+=(
            --template=./templates/xcm-bench-template.hbs
            --output="./parachains/runtimes/$chain_type/$runtime/src/weights/xcm/"
          )
        ;;
        *)
          die "Kind $kind is not supported for $REPOSITORY in bench_pallet"
        ;;
      esac
    ;;
    *)
      die "Repository $REPOSITORY is not supported in bench_pallet"
    ;;
  esac

  cargo_run "${cargo_args[@]}"
}


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
  local cargo_args
  case "$REPOSITORY" in
    substrate)
      cargo_args=(
        "${bench_overhead_common_args[@]}"
        --header=./HEADER-APACHE2
        --weight-path="./frame/support/src/weights"
        --chain="dev"
      )
    ;;
    polkadot)
      local runtime="${ARGS[runtime]}"
      cargo_args=(
        "${bench_overhead_common_args[@]}"
        --header=./file_header.txt
        --weight-path="./runtime/$runtime/constants/src/weights"
        --chain="$runtime-dev"
      )
    ;;
    cumulus)
      local chain_type="${ARGS[type]}"
      local runtime="${ARGS[runtime]}"

      cargo_args=(
        --bin=polkadot-parachain
        "${bench_overhead_common_args[@]}"
        --header=./file_header.txt
        --weight-path="./cumulus/parachains/runtimes/$chain_type/$runtime/src/weights"
        --chain="$runtime"
      )
    ;;
    *)
      die "Repository $REPOSITORY is not supported in bench_overhead"
    ;;
  esac

  cargo_run "${cargo_args[@]}"
}

process_args() {
  case "$PRESET" in
    runtime|pallet|xcm)
      echo 'Running bench_pallet'
      bench_pallet "$PRESET"
    ;;
    overhead)
      echo 'Running bench_overhead'
      bench_overhead "$PRESET"
    ;;
    *)
      die "Invalid preset $PRESET to process_args"
    ;;
  esac
}

process_args
