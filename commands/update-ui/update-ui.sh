#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  # setup.
  cmd_runner_setup

  get_arg required --rust_version "$@"
  RUST_VERSION="${out:-""}"

  get_arg required --target_path "$@"
  target_path="${out:-""}"


  if [[ ! -z "${RUST_VERSION}" ]]; then
    rustup install $RUST_VERSION
    rustup component add rust-src --toolchain $RUST_VERSION
  fi

  # Ensure we run the ui tests
  export RUN_UI_TESTS=1
  # We don't need any wasm files for ui tests
  export SKIP_WASM_BUILD=1
  # Let trybuild overwrite the .stderr files
  export TRYBUILD=overwrite

  # Run all the relevant UI tests
  #
  # Any new UI tests in different crates need to be added here as well.
  rustup run $RUST_VERSION cargo test -p sp-runtime-interface ui
  rustup run $RUST_VERSION cargo test -p sp-api-test ui
  rustup run $RUST_VERSION cargo test -p frame-election-provider-solution-type ui
  rustup run $RUST_VERSION cargo test -p frame-support-test ui

  # commit.
  git add .
  git commit -m "${COMMIT_MESSAGE}"

  # Push the results to the target branch
  git remote add \
    github \
    "https://token:${GITHUB_TOKEN}@github.com/${GH_CONTRIBUTOR}/${GH_CONTRIBUTOR_REPO}.git"
  git push github "HEAD:${GH_CONTRIBUTOR_BRANCH}"
}

main "$@"
