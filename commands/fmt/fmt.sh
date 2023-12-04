#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  # setup.
  cmd_runner_setup

  # format rust code.
  cargo +nightly fmt

  # format toml.
  # since paritytech/ci-unified:bullseye-1.73.0-2023-11-01-v20231204 includes taplo-cli
  taplo format

  # commit.
  git add .
  git commit -m "$COMMIT_MESSAGE"

  # Push the results to the target branch
  git remote add \
    github \
    "https://token:${GITHUB_TOKEN}@github.com/${GH_CONTRIBUTOR}/${GH_CONTRIBUTOR_REPO}.git"
  git push github "HEAD:${GH_CONTRIBUTOR_BRANCH}"
}

main "$@"
