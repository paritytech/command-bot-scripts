#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit
shopt -s globstar

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

get_arg optional --pallet "$@"
PALLET="${out:-""}"
BASE_COMMAND="$(dirname "${BASH_SOURCE[0]}")/../bench/bench.sh --subcommand=pallet"
WEIGHTS=()

# find all weights files
for f in **/weights/${PALLET}.rs; do
  WEIGHTS+=("$f")
done

# convert pallet_ranked_collective to ranked-collective
CLEAN_PALLET=$(echo $PALLET | sed 's/pallet_//g' | sed 's/_/-/g')

# add substrate pallet weights to a list
SUBSTRATE_PALLET_PATH=$(ls substrate/frame/$CLEAN_PALLET/src/weights.rs)
if [ ! -z "${SUBSTRATE_PALLET_PATH}" ]; then
  WEIGHTS+=("$SUBSTRATE_PALLET_PATH")
fi

COMMANDS=()

for f in ${WEIGHTS[@]}; do
  # f == "cumulus/parachains/runtimes/assets/asset-hub-rococo/src/weights/pallet_balances.rs"
  TARGET_DIR=$(echo $f | cut -d'/' -f 1)

  case $TARGET_DIR in
    cumulus)
      TYPE=$(echo $f | cut -d'/' -f 2)
      # Example: cumulus/parachains/runtimes/assets/asset-hub-rococo/src/weights/pallet_balances.rs
      if [ "$TYPE" == "parachains" ]; then
        RUNTIME=$(echo $f | cut -d'/' -f 5)
        RUNTIME_DIR=$(echo $f | cut -d'/' -f 4)
        COMMANDS+=("$BASE_COMMAND --runtime=$RUNTIME --runtime_dir=$RUNTIME_DIR --target_dir=$TARGET_DIR --pallet=$PALLET")
      fi
      ;;
    polkadot)
      # Example: polkadot/runtime/rococo/src/weights/pallet_balances.rs
      RUNTIME=$(echo $f | cut -d'/' -f 3)
      COMMANDS+=("$BASE_COMMAND --runtime=$RUNTIME --target_dir=$TARGET_DIR --pallet=$PALLET")
      ;;
    substrate)
      # Example: substrate/frame/contracts/src/weights.rs
      COMMANDS+=("$BASE_COMMAND --target_dir=$TARGET_DIR --pallet=$PALLET")
      ;;
    *)
      echo "Unknown dir: $TARGET_DIR"
      exit 1
      ;;
  esac
done

for cmd in "${COMMANDS[@]}"; do
  echo "Running command: $cmd"
  . $cmd
done
