#!/bin/bash
# Initially based on https://github.com/paritytech/bench-bot/blob/cd3b2943d911ae29e41fe6204788ef99c19412c3/bench.js

# Most external variables used in this script, such as $GH_CONTRIBUTOR, are
# related to https://github.com/paritytech/try-runtime-bot

# This script relies on $GITHUB_TOKEN which is probably a protected GitLab CI
# variable; if this assumption holds true, it is implied that this script should
# be ran only on protected pipelines

set -eu -o pipefail
shopt -s inherit_errexit

# realpath allows to reuse the current
BENCH_ROOT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

. "$BENCH_ROOT_DIR/../utils.sh"
. "$BENCH_ROOT_DIR/../cmd_runner.sh"

repository_name="$(basename "$PWD")"

get_arg optional --target_dir "$@"
target_dir="${out:-""}"

output_path="."

profile="production"

if [[ "$repository_name" == "polkadot-sdk" ]]; then
  output_path="./$target_dir"
  profile="release"
fi

cargo_run_benchmarks="cargo run --quiet --profile=${profile}"

echo "Repository: $repository_name"
echo "Target Dir: $target_dir"
echo "Output Path: $output_path"

cargo_run() {
  echo "Running $cargo_run_benchmarks" "${args[@]}"

  # if not patched with PATCH_something=123 then use --locked
  if [[ -z "${BENCH_PATCHED:-}" ]]; then
    cargo_run_benchmarks+=" --locked"
  fi

  $cargo_run_benchmarks "${args[@]}"
}


main() {
  cmd_runner_setup

  # Remove the "github" remote since the same repository might be reused by a
  # GitLab runner, therefore the remote might already exist from a previous run
  # in case it was not cleaned up properly for some reason
  &>/dev/null git remote remove github || :

  tmp_dirs=()
  cleanup() {
    exit_code=$?
    # Clean up the "github" remote at the end since it contains the
    # $GITHUB_TOKEN secret, which is only available for protected pipelines on
    # GitLab
    &>/dev/null git remote remove github || :
    rm -rf "${tmp_dirs[@]}"
    exit $exit_code
  }
  trap cleanup EXIT

  if [[
    "${UPSTREAM_MERGE:-}" != "n" &&
    ("${GH_OWNER_BRANCH:-}")
  ]]; then
    echo "Merging $GH_OWNER/$GH_OWNER_REPO#$GH_OWNER_BRANCH into $GH_CONTRIBUTOR_BRANCH"
    git remote add \
      github \
      "https://token:${GITHUB_TOKEN}@github.com/${GH_OWNER}/${GH_OWNER_REPO}.git"
    git pull --no-edit github "$GH_OWNER_BRANCH"
    git remote remove github
  fi

  # shellcheck disable=SC2119
  cmd_runner_apply_patches

  set -x

  get_arg required --subcommand "$@"
  local subcommand="${out:-""}"

  case "$subcommand" in
    runtime|pallet|xcm)
      echo 'Running bench_pallet'
      . "$BENCH_ROOT_DIR/lib/bench-pallet.sh" "$@"
    ;;
    overhead)
      echo 'Running bench_overhead'
      . "$BENCH_ROOT_DIR/lib/bench-overhead.sh" "$@"
    ;;
    all)
      echo "Running all-$target_dir"
      . "$BENCH_ROOT_DIR/lib/bench-all-${target_dir}.sh" "$@"
    ;;
    *)
      die "Invalid subcommand $subcommand to process_args"
    ;;
  esac

  set +x

  # in case we used diener to patch some dependency during benchmark execution,
  # revert the patches so that they're not included in the diff
  git checkout --quiet HEAD Cargo.toml

  # Save the generated weights to GitLab artifacts in case commit+push fails
  echo "Showing weights diff for command"
  git diff -P | tee -a "${ARTIFACTS_DIR}/weights.patch"
  echo "Wrote weights patch to \"${ARTIFACTS_DIR}/weights.patch\""

  # Commits the weights and pushes it
  git add .

  # instead of using `cargo run --locked`, we allow the Cargo files to be updated
  # but avoid committing them. It is so `cmd_runner_apply_patches` can work
  git restore --staged Cargo.*

  git commit -m "$COMMIT_MESSAGE"

  # Push the results to the target branch
  git remote add \
    github \
    "https://token:${GITHUB_TOKEN}@github.com/${GH_CONTRIBUTOR}/${GH_CONTRIBUTOR_REPO}.git"
  git push github "HEAD:${GH_CONTRIBUTOR_BRANCH}"
}

main "$@"
