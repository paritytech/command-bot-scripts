#!/usr/bin/env bash
# originally moved from https://github.com/paritytech/cumulus/blob/445f9277ab55b4d930ced4fbbb38d27c617c6658/scripts/benchmarks-ci.sh

# default RUST_LOG is warn, but could be overridden
export RUST_LOG="${RUST_LOG:-error}"

POLKADOT_PARACHAIN=./target/production/polkadot-parachain

run_cumulus_bench() {
  local artifactsDir="$ARTIFACTS_DIR"
  local category=$1
  local runtimeName=$2
  local paraId=$3

  local benchmarkOutput=./parachains/runtimes/$category/$runtimeName/src/weights
  local benchmarkRuntimeChain
  if [[ ! -z "$paraId" ]]; then
     benchmarkRuntimeChain="${runtimeName}-dev-$paraId"
  else
     benchmarkRuntimeChain="$runtimeName-dev"
  fi

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
    local output_file="${pallet//::/_}"
    local extra_args=""
    # a little hack for pallet_xcm_benchmarks - we want to force custom implementation for XcmWeightInfo
    if [[ "$pallet" == "pallet_xcm_benchmarks::generic" ]] || [[ "$pallet" == "pallet_xcm_benchmarks::fungible" ]]; then
      output_file="xcm/$output_file"
      extra_args="--template=./templates/xcm-bench-template.hbs"
    fi
    $POLKADOT_PARACHAIN benchmark pallet \
      $extra_args \
      --chain="${benchmarkRuntimeChain}" \
      --execution=wasm \
      --wasm-execution=compiled \
      --pallet="$pallet" \
      --no-storage-info \
      --no-median-slopes \
      --no-min-squares \
      --extrinsic='*' \
      --steps=50 \
      --repeat=20 \
      --json \
      --header=./file_header.txt \
      --output="${benchmarkOutput}/${output_file}.rs" >> "$artifactsDir/${pallet}_benchmark.json"
  done
}


echo "[+] Compiling benchmarks..."
cargo build --profile production --locked --features=runtime-benchmarks

# Assets
run_cumulus_bench assets asset-hub-kusama
run_cumulus_bench assets asset-hub-polkadot
run_cumulus_bench assets asset-hub-westend

# Collectives
run_cumulus_bench collectives collectives-polkadot

# Bridge Hubs
run_cumulus_bench bridge-hubs bridge-hub-polkadot
run_cumulus_bench bridge-hubs bridge-hub-kusama
run_cumulus_bench bridge-hubs bridge-hub-rococo

# Glutton
run_cumulus_bench glutton glutton-kusama 1300
