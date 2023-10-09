#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  # setup.
  cmd_runner_setup

  get_arg optional --chain "$@"
  local chain="${out:-""}"

  set -x
  export RUST_LOG="${RUST_LOG:-remote-ext=debug,runtime=trace}"

  cargo build --release

  "./target/release/polkadot sync --chain=$chain"

  git add .
  git commit -m "$COMMIT_MESSAGE"

  git remote add \
    github \
    "https://token:${GITHUB_TOKEN}@github.com/${GH_CONTRIBUTOR}/${GH_CONTRIBUTOR_REPO}.git"
  git push github "HEAD:${GH_CONTRIBUTOR_BRANCH}"
}

main "$@"
