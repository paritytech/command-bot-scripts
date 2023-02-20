#!/usr/bin/env bash
# originally moved from https://github.com/paritytech/cumulus/blob/445f9277ab55b4d930ced4fbbb38d27c617c6658/scripts/benchmarks-ci.sh

run_cumulus_bench() {
  local artifactsDir="$ARTIFACTS_DIR"
  local category=$1
  local runtimeName=$2

  local benchmarkOutput=./parachains/runtimes/$category/$runtimeName/src/weights

  if [[ $runtimeName =~ ^(statemint|statemine|westmint)$ ]]; then
    local pallets=(
      pallet_assets
      pallet_balances
      pallet_collator_selection
      pallet_multisig
      pallet_proxy
      pallet_session
      pallet_timestamp
      pallet_utility
      pallet_uniques
      cumulus_pallet_xcmp_queue
      frame_system
      pallet_xcm_benchmarks::generic
      pallet_xcm_benchmarks::fungible
    )
  elif [[ $runtimeName == "collectives-polkadot" ]]; then
    local pallets=(
      pallet_alliance
      pallet_balances
      pallet_collator_selection
      pallet_collective
      pallet_multisig
      pallet_proxy
      pallet_session
      pallet_timestamp
      pallet_utility
      cumulus_pallet_xcmp_queue
      frame_system
    )
  elif [[ $runtimeName =~ ^(bridge-hub-kusama|bridge-hub-polkadot)$ ]]; then
    local pallets=(
      frame_system
      pallet_balances
      pallet_collator_selection
      pallet_multisig
      pallet_session
      pallet_timestamp
      pallet_utility
      cumulus_pallet_xcmp_queue
      pallet_xcm_benchmarks::generic
      pallet_xcm_benchmarks::fungible
    )
  elif [[ $runtimeName == "bridge-hub-rococo" ]]; then
    local pallets=(
      frame_system
      pallet_balances
      pallet_collator_selection
      pallet_multisig
      pallet_session
      pallet_timestamp
      pallet_utility
      cumulus_pallet_xcmp_queue
      pallet_xcm_benchmarks::generic
      pallet_xcm_benchmarks::fungible
    )
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
    $artifactsDir/polkadot-parachain benchmark pallet \
      $extra_args \
      --chain="$runtimeName-dev" \
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
run_cumulus_bench assets statemine
run_cumulus_bench assets statemint
run_cumulus_bench assets westmint

# Collectives
run_cumulus_bench collectives collectives-polkadot

# Bridge Hubs
run_cumulus_bench bridge-hubs bridge-hub-polkadot
run_cumulus_bench bridge-hubs bridge-hub-kusama
run_cumulus_bench bridge-hubs bridge-hub-rococo
