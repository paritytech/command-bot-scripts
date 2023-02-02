#!/bin/bash

# This file is separated to simplify testing the final pure command output

set -eu -o pipefail
shopt -s inherit_errexit

. "../../utils.sh"
. "../../cmd_runner.sh"

cargo_run_benchmarks="cargo run --quiet --profile=production"
current_folder="$(basename "$PWD")"

get_arg optional --repo "$@"
repository="${out:=$current_folder}"

echo "Repo: $repository"

cargo_run() {
  echo "Running $cargo_run_benchmarks" "${args[@]}"

  # if not patched with PATCH_something=123 then use --locked
  if [[ -z "${BENCH_PATCHED:-}" ]]; then
    cargo_run_benchmarks+=" --locked"
  fi

  $cargo_run_benchmarks "${args[@]}"
}
