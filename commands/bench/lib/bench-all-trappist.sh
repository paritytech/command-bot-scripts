#!/bin/bash

# Runs all benchmarks for all pallets, for a given runtime, provided by $1

# This is a workaround for `UnknownOpcode(192)` error.
# TODO. Remove this when migrated to 0.9.42+
echo "[+] Apply workaround... (remove after 0.9.42+)"
rustup toolchain install nightly-2023-01-01 --profile minimal --component rustfmt
rustup target add wasm32-unknown-unknown --toolchain nightly-2023-01-01
ln -sfn /usr/local/rustup/toolchains/nightly-2023-01-01-x86_64-unknown-linux-gnu /usr/local/rustup/toolchains/nightly-x86_64-unknown-linux-gnu
echo "Toolchains available:"
rustup toolchain list

get_arg required --runtime "$@"
runtime="${out:-""}"

chain="${runtime}-dev"

# default RUST_LOG is error, but could be overridden
export RUST_LOG="${RUST_LOG:-error}"

echo "[+] Compiling benchmarks..."
cargo build --profile $profile --locked --features=runtime-benchmarks

TRAPPIST_BIN="./target/$profile/trappist-node"

# Update the block and extrinsic overhead weights.
echo "[+] Benchmarking block and extrinsic overheads..."
OUTPUT=$(
  $TRAPPIST_BIN benchmark overhead \
  --chain=$chain \
  --execution=wasm \
  --wasm-execution=compiled \
  --weight-path="./runtime/${runtime}/src/weights/" \
  --warmup=10 \
  --repeat=100 \
  --header=./templates/file_header.txt 2>&1
)
if [ $? -ne 0 ]; then
  echo "$OUTPUT" >> "$ERR_FILE"
  echo "[-] Failed to benchmark the block and extrinsic overheads. Error written to $ERR_FILE; continuing..."
fi

# Load all pallet names in an array.
PALLETS=($(
  $TRAPPIST_BIN benchmark pallet --list --chain=$chain |\
    tail -n+2 |\
    cut -d',' -f1 |\
    sort |\
    uniq
))

echo "[+] Benchmarking ${#PALLETS[@]} pallets for runtime $runtime"

# Define the error file.
ERR_FILE="${ARTIFACTS_DIR}/benchmarking_errors.txt"
# Delete the error file before each run.
rm -f $ERR_FILE

# Benchmark each pallet.
for PALLET in "${PALLETS[@]}"; do
  echo "[+] Benchmarking $PALLET for $runtime";

  output_file=""
  if [[ $PALLET == *"::"* ]]; then
    # translates e.g. "pallet_foo::bar" to "pallet_foo_bar"
    output_file="${PALLET//::/_}.rs"
  fi

  local extra_args=""
  if [[ "$PALLET" == "pallet_xcm_benchmarks::generic" ]] || [[ "$PALLET" == "pallet_xcm_benchmarks::fungible" ]]; then
    output_file="xcm/$output_file"
    extra_args="--template=./templates/xcm-bench-template.hbs"
  fi

  OUTPUT=$(
    $TRAPPIST_BIN benchmark pallet \
    $extra_args \
    --chain=$chain \
    --steps=50 \
    --repeat=20 \
    --no-storage-info \
    --no-median-slopes \
    --no-min-squares \
    --pallet="$PALLET" \
    --extrinsic="*" \
    --execution=wasm \
    --wasm-execution=compiled \
    --header=./templates/file_header.txt \
    --output="./runtime/${runtime}/src/weights/${output_file}" 2>&1
  )
  if [ $? -ne 0 ]; then
    echo "$OUTPUT" >> "$ERR_FILE"
    echo "[-] Failed to benchmark $PALLET. Error written to $ERR_FILE; continuing..."
  fi
done

# Check if the error file exists.
if [ -f "$ERR_FILE" ]; then
  echo "[-] Some benchmarks failed. See: $ERR_FILE"
else
  echo "[+] All benchmarks passed."
fi
