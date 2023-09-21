#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  # setup.
  cmd_runner_setup

  get_arg optional --rust_version "$@"
  RUST_VERSION="${out:-""}"

  "./scripts/update-ui-tests.sh" "$RUST_VERSION"

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
