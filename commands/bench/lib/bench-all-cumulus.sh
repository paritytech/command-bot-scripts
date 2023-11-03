#!/usr/bin/env bash
# originally moved from https://github.com/paritytech/cumulus/blob/445f9277ab55b4d930ced4fbbb38d27c617c6658/scripts/benchmarks-ci.sh

# default RUST_LOG is warn, but could be overridden
export RUST_LOG="${RUST_LOG:-error}"

. "$BENCH_ROOT_DIR/../utils.sh"

POLKADOT_PARACHAIN="./target/$profile/polkadot-parachain"

run_cumulus_bench() {
  local artifactsDir="$ARTIFACTS_DIR"
  local category=$1
  local runtimeName=$2
  local paraId=${3:-}

  local benchmarkOutput="$output_path/parachains/runtimes/$category/$runtimeName/src/weights"
  local benchmarkRuntimeChain
  if [[ ! -z "$paraId" ]]; then
     benchmarkRuntimeChain="${runtimeName}-dev-$paraId"
  else
     benchmarkRuntimeChain="$runtimeName-dev"
  fi

  local benchmarkMetadataOutputDir="$artifactsDir/$runtimeName"
  mkdir -p "$benchmarkMetadataOutputDir"

  # Load all pallet names in an array.
  echo "[+] Listing pallets for runtime $runtimeName for chain: $benchmarkRuntimeChain ..."
  local pallets=($(
    $POLKADOT_PARACHAIN benchmark pallet --list --chain="${benchmarkRuntimeChain}" |\
      tail -n+2 |\
      cut -d',' -f1 |\
      sort |\
      uniq
  ))

  if [ ${#pallets[@]} -ne 0 ]; then
    echo "[+] Benchmarking ${#pallets[@]} pallets for runtime $runtimeName for chain: $benchmarkRuntimeChain, pallets:"
    for pallet in "${pallets[@]}"; do
        echo "   [+] $pallet"
    done
  else
    echo "$runtimeName pallet list not found in benchmarks-ci.sh"
    exit 1
  fi

  for pallet in "${pallets[@]}"; do
    # (by default) do not choose output_file, like `pallet_assets.rs` because it does not work for multiple instances
    # `benchmark pallet` command will decide the output_file name if there are multiple instances
    local output_file=""
    local extra_args=""
    # a little hack for pallet_xcm_benchmarks - we want to force custom implementation for XcmWeightInfo
    if [[ "$pallet" == "pallet_xcm_benchmarks::generic" ]] || [[ "$pallet" == "pallet_xcm_benchmarks::fungible" ]]; then
      output_file="xcm/${pallet//::/_}.rs"
      extra_args="--template=$output_path/templates/xcm-bench-template.hbs"
    fi
    $POLKADOT_PARACHAIN benchmark pallet \
      $extra_args \
      --chain="${benchmarkRuntimeChain}" \
      --wasm-execution=compiled \
      --pallet="$pallet" \
      --no-storage-info \
      --no-median-slopes \
      --no-min-squares \
      --extrinsic='*' \
      --steps=50 \
      --repeat=20 \
      --json \
      --header="$output_path/file_header.txt" \
      --output="${benchmarkOutput}/${output_file}" >> "$benchmarkMetadataOutputDir/${pallet//::/_}_benchmark.json"
  done
}


echo "[+] Compiling benchmarks..."
cargo build --profile $profile --locked --features=runtime-benchmarks -p polkadot-parachain-bin

# Run benchmarks for all pallets of a given runtime if runtime argument provided
get_arg optional --runtime "$@"
runtime="${out:-""}"

if [[ $runtime ]]; then
  case "$runtime" in
    asset-*)
      category="assets"
    ;;
    collectives-*)
      category="collectives"
    ;;
    bridge-*)
      category="bridge-hubs"
    ;;
    contracts-*)
      category="contracts"
    ;;
    glutton-*)
      category="glutton"
      $paraId="1300"
    ;;
    *)
      echo "Unknown runtime: $runtime"
      exit 1
    ;;
  esac

  run_cumulus_bench $category $runtime $paraId

  exit 0
else # run all
  # Assets
  run_cumulus_bench assets asset-hub-kusama
  run_cumulus_bench assets asset-hub-polkadot
  run_cumulus_bench assets asset-hub-westend
  run_cumulus_bench assets asset-hub-rococo
  
  # Collectives
  run_cumulus_bench collectives collectives-polkadot
  run_cumulus_bench collectives collectives-westend
  
  # Bridge Hubs
  run_cumulus_bench bridge-hubs bridge-hub-polkadot
  run_cumulus_bench bridge-hubs bridge-hub-kusama
  run_cumulus_bench bridge-hubs bridge-hub-rococo
  
  # Glutton
  run_cumulus_bench glutton glutton-kusama 1300
  run_cumulus_bench glutton glutton-westend 1300
fi
