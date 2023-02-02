#!/bin/bash

. "common.sh"

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
  local kind="$1"
  local runtime="$2"

  local args
  case "$repository" in
    substrate)
      local pallet="$3"

      args=(
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

          args+=(
            --header="./HEADER-APACHE2"
            --output="./frame/$output_dir/src/weights.rs"
            --template=./.maintain/frame-weight-template.hbs
          )
        ;;
        *)
          die "Kind $kind is not supported for $repository in bench_pallet"
        ;;
      esac
    ;;
    polkadot)
      local pallet="$3"

      args=(
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
          args+=(
            --header=./file_header.txt
            --output="${weights_dir}/"
          )
        ;;
        xcm)
          args+=(
            --header=./file_header.txt
            --template=./xcm/pallet-xcm-benchmarks/template.hbs
            --output="${weights_dir}/xcm/"
          )
        ;;
        *)
          die "Kind $kind is not supported for $repository in bench_pallet"
        ;;
      esac
    ;;
    cumulus)
      local chain_type="$3"
      local pallet="$4"

      args=(
        --bin=polkadot-parachain
        --features=runtime-benchmarks
        "${bench_pallet_common_args[@]}"
        --pallet="$pallet"
        --chain="${runtime}-dev"
        --header=./file_header.txt
      )

      case "$kind" in
        pallet)
          args+=(
            --output="./parachains/runtimes/$chain_type/$runtime/src/weights/"
          )
        ;;
        xcm)
          mkdir -p "./parachains/runtimes/$chain_type/$runtime/src/weights/xcm"
          args+=(
            --template=./templates/xcm-bench-template.hbs
            --output="./parachains/runtimes/$chain_type/$runtime/src/weights/xcm/"
          )
        ;;
        *)
          die "Kind $kind is not supported for $repository in bench_pallet"
        ;;
      esac
    ;;
    *)
      die "Repository $repository is not supported in bench_pallet"
    ;;
  esac

  cargo_run "${args[@]}"
}

bench_pallet "$@"
