#!/usr/bin/env bash

. "$(realpath "$(dirname "${BASH_SOURCE[0]}")/utils.sh")"

set -eu -o pipefail
shopt -s inherit_errexit

cmd_runner_display_rust_toolchain() {
  cargo --version
  rustc --version
  cargo +nightly --version
  rustc +nightly --version
}

cmd_runner_setup() {
  # set the Git user, otherwise Git commands will fail
  git config --global user.name command-bot
  git config --global user.email "<>"
  git config --global pull.rebase false

  # Reset the branch to how it was on GitHub when the bot command was issued
  git reset --hard "$GH_HEAD_SHA"

  # Some commands push commits to the requester's branch, therefore we should
  # pull the branch from GitHub before running a command it so that its
  # execution takes into account commits pushed before its start
  git remote add \
    github \
    "https://token:${GITHUB_TOKEN}@github.com/${GH_CONTRIBUTOR}/${GH_CONTRIBUTOR_REPO}.git" || :
  git pull --ff --no-edit github "$GH_CONTRIBUTOR_BRANCH"
  git remote remove github || :

  cmd_runner_display_rust_toolchain

  # https://github.com/paritytech/substrate/pull/10700
  # https://github.com/paritytech/substrate/blob/b511370572ac5689044779584a354a3d4ede1840/utils/wasm-builder/src/wasm_project.rs#L206
  export WASM_BUILD_WORKSPACE_HINT="$PWD"
}
