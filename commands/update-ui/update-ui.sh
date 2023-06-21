#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../cmd_runner.sh"

main() {
  # setup.
  cmd_runner_setup

  get_arg required --rust_version "$@"
  rust_version="${out:-""}"

  get_arg required --target_path "$@"
  target_path="${out:-""}"

  if [[ -z "${rust_version}" ]]; then
    die "missing rust version argument"
  fi

  # This script uses rustup to install the required rust version.
  # Doing that in CI feels rather ugly, but sadly there's currently no mechanism
  # in command-bot to use a different CI image for individual jobs, so this is
  # the best we can do.
  "$target_path/maintain/update-rust-stable.sh" "${rust_version}"

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
