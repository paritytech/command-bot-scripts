#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

# Function to check syncing status
check_syncing() {
  # Send the system_health request and parse the isSyncing field
  RESPONSE=$(curl --silent --request POST http://127.0.0.1:9944 \
    --header 'Content-Type: application/json' \
    --data-raw '{"jsonrpc": "2.0", "method": "system_health", "params": [], "id": "1"}')

  # Check for errors in the curl command
  if [ $? -ne 0 ]; then
    echo "Error: Unable to send request to Polkadot node"
    exit 1
  fi

  IS_SYNCING=$(echo $RESPONSE | jq -r '.result.isSyncing')

  # Check for errors in the jq command or missing field in the response
  if [ $? -ne 0 ] || [ "$IS_SYNCING" == "null" ]; then
    echo "Error: Unable to parse sync status from response"
    exit 1
  fi

  # Return the isSyncing value
  echo $IS_SYNCING
}

main() {
  # setup.
  cmd_runner_setup

  get_arg required --chain "$@"
  local chain="${out:-""}"

  get_arg required --type "$@"
  local type="${out:-""}"

  export RUST_LOG="${RUST_LOG:-remote-ext=debug,runtime=trace}"

  cargo build --release

  cp "./target/release/polkadot" ./polkadot-bin

  # Start sync.
  # "&" runs the process in the background
  # "> /dev/tty" redirects the output of the process to the terminal
  nohup ./polkadot-bin --sync="$type" --chain="$chain" > "$ARTIFACTS_DIR/sync.log" 2>&1 &

  # Get the PID of process
  POLKADOT_SYNC_PID=$!

  sleep 10

  # Poll the node every 100 seconds until syncing is complete
  while [ $(check_syncing) == "true" ]; do
    echo "Node is still syncing..."
    sleep 100
  done

  echo "Syncing is complete!"

  # Stop the Polkadot node process once syncing is complete
  kill $POLKADOT_SYNC_PID

  # Exit successfully
  exit 0
}

main "$@"
