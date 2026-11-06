#!/usr/bin/env bash
# Tests for actions/dev-version and actions/mark-version-line (RFC-0013).
# Needs only bash and git: ./tests/dev-version/run.sh

set -uo pipefail
export LC_ALL=C

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
DEV_VERSION="$ROOT/actions/dev-version/dev-version.sh"
MARK="$ROOT/actions/mark-version-line/mark-version-line.sh"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "ok   - $1"; }
ko() { FAIL=$((FAIL + 1)); echo "FAIL - $1"; [[ -n ${2:-} ]] && echo "       $2"; }

# --- SemVer helpers -----------------------------------------------------------

# shellcheck source=SCRIPTDIR/../../actions/dev-version/dev-version.sh
source "$DEV_VERSION"
set +e

assert_order() {
  local name=$1; shift
  local -a v=("$@")
  local i j
  for ((i = 0; i < ${#v[@]}; i++)); do
    for ((j = 0; j < ${#v[@]}; j++)); do
      semver_cmp "${v[i]}" "${v[j]}"
      local want=0
      ((i < j)) && want=-1
      ((i > j)) && want=1
      if ((CMP != want)); then
        ko "$name" "cmp(${v[i]}, ${v[j]}) = $CMP, want $want"
        return
      fi
    done
  done
  ok "$name"
}

# SemVer 2.0.0, section 11.
assert_order "semver spec precedence" \
  v1.0.0-alpha v1.0.0-alpha.1 v1.0.0-alpha.beta v1.0.0-beta v1.0.0-beta.2 \
  v1.0.0-beta.11 v1.0.0-rc.1 v1.0.0 v1.0.1 v1.2.0 v1.10.0 v2.0.0

# RFC-0013 orderings.
assert_order "rfc order: dev builds between releases and across majors" \
  v2.4.1 v2.4.2-dev.9.g1234567 v2.4.2-dev.76.g6399077 v2.4.2 \
  v3.0.0-0 v3.0.0-beta.5 v3.0.0-beta.5.dev.12.gabc1234 v3.0.0-beta.6
assert_order "rfc order: marker lines" \
  v2.4.13 v2.5.0-0 v2.5.0-0.dev.3.gaaaaaaa v2.5.0-0.dev.12.gaaaaaaa v2.5.0-alpha.1 v2.5.0
assert_order "rfc order: dev sorts between beta and rc" \
  v3.2.0-alpha.1 v3.2.0-beta.0 v3.2.0-dev.3.gabc1234 v3.2.0-rc.1 v3.2.0
assert_order "large numbers compared numerically" \
  v1.0.0-9 v1.0.0-10 v1.0.0-99999999999999999998 v1.0.0-99999999999999999999 v99999999999999999999.0.0

for inc_case in 0:1 8:9 9:10 19:20 99:100 109:110 999:1000 \
  9223372036854775807:9223372036854775808 99999999999999999999:100000000000000000000; do
  _inc_num "${inc_case%%:*}"
  if [[ $REPLY == "${inc_case#*:}" ]]; then ok "increment ${inc_case%%:*}"; else ko "increment ${inc_case%%:*}" "got '$REPLY', want '${inc_case#*:}'"; fi
done

for v in v1.2.3 v0.0.0 v1.2.3-0 v1.2.3-alpha.1 v1.2.3-x-y.0a v2.4.2-dev.76.g6399077 v1.2.3-0123abc; do
  if is_semver "$v"; then ok "valid: $v"; else ko "valid: $v"; fi
done
for v in 1.2.3 v1.2 v1.2.3.4 v01.2.3 v1.02.3 v1.2.3- v1.2.3-01 v1.2.3-a..b v1.2.3+meta v1.2.3-a+b vX.Y.Z latest; do
  if is_semver "$v"; then ko "invalid: $v"; else ok "invalid: $v"; fi
done

# --- dev-version against real repositories ------------------------------------

new_repo() {
  local dir="$WORK/$1"
  git init -q -b main "$dir"
  cd "$dir" || exit 1
}

commit() {
  local i
  for ((i = 0; i < ${1:-1}; i++)); do
    git commit -q --allow-empty -m "commit $RANDOM"
  done
}

short() { git rev-parse --short=7 "${1:-HEAD}"; }

# run_dev_version BRANCH [REF] -> prints the version, returns the script status.
run_dev_version() {
  local out="$WORK/out.$RANDOM"
  : >"$out"
  DEV_VERSION_BRANCH=$1 DEV_VERSION_REF=${2:-HEAD} GITHUB_OUTPUT=$out \
    bash "$DEV_VERSION" 2>"$WORK/stderr" || return $?
  sed -n 's/^version=//p' "$out"
}

expect_version() {
  local name=$1 want=$2 branch=$3 ref=${4:-HEAD} got
  got=$(run_dev_version "$branch" "$ref")
  local status=$?
  if ((status != 0)); then
    ko "$name" "exit $status: $(cat "$WORK/stderr")"
  elif [[ $got != "$want" ]]; then
    ko "$name" "got '$got', want '$want'"
  else
    ok "$name"
  fi
}

expect_failure() {
  local name=$1 pattern=$2 branch=$3
  if run_dev_version "$branch" >/dev/null; then
    ko "$name" "expected failure"
  elif ! grep -q -- "$pattern" "$WORK/stderr"; then
    ko "$name" "stderr does not mention '$pattern': $(cat "$WORK/stderr")"
  else
    ok "$name"
  fi
}

# Stable base tag: bump the patch.
new_repo stable
commit; git tag v2.4.1; commit 3
expect_version "stable tag bumps patch" "v2.4.2-dev.3.g$(short)" main
expect_version "refs/heads/ prefix accepted" "v2.4.2-dev.3.g$(short)" refs/heads/main
git tag -a v2.4.2-rc.1 -m rc HEAD~1
expect_version "annotated prerelease tag extends prerelease" "v2.4.2-rc.1.dev.1.g$(short)" main
expect_version "ref input versions another commit" "v2.4.2-dev.1.g$(short HEAD~2)" main HEAD~2

# Distance 0 still produces a development version, never the release itself.
new_repo distance0
commit; git tag v1.0.0
expect_version "commit on a stable tag" "v1.0.1-dev.0.g$(short)" main

# Patch increments beyond the shell's 64-bit integer range.
for patch_case in \
  "9223372036854775806:9223372036854775807" \
  "9223372036854775807:9223372036854775808" \
  "99999999999999999999:100000000000000000000" \
  "18446744073709551615:18446744073709551616"; do
  new_repo "overflow-${patch_case%%:*}"
  commit; git tag "v1.0.${patch_case%%:*}"; commit
  expect_version "patch ${patch_case%%:*} + 1" "v1.0.${patch_case#*:}-dev.1.g$(short)" main
done

# Prerelease base tag: extend it.
new_repo prerelease
commit; git tag v3.0.0-beta.5; commit 12
expect_version "prerelease tag is extended" "v3.0.0-beta.5.dev.12.g$(short)" release/v3.0

# Highest tag, not nearest; SemVer precedence, not sort -V.
new_repo precedence
commit; git tag v3.0.0; commit; git tag v3.0.0-beta.5; commit 2
expect_version "stable beats its prereleases (not sort -V)" "v3.0.1-dev.3.g$(short)" main
new_repo numeric
commit; git tag v1.10.0; commit; git tag v1.9.0; commit
expect_version "1.10 beats 1.9" "v1.10.1-dev.2.g$(short)" main

# A marker on the same commit as a release tag wins on the default branch.
new_repo marker
commit; git tag v2.4.0; commit; git tag v2.4.13; git tag v2.5.0-0; commit 3
expect_version "marker beats release on the same commit" "v2.5.0-0.dev.3.g$(short)" main

# Invalid tags are ignored.
new_repo invalid
commit; git tag v1.2.3; commit
for t in v9.9 v9.9.9.9 v09.0.0 v9.0.0+meta latest 9.9.9 pkg/domain/v9.9.9 vnext; do git tag "$t"; done
commit
expect_version "non-SemVer tags are ignored" "v1.2.4-dev.2.g$(short)" main

# Unreachable tags are ignored.
new_repo unreachable
commit; git tag v1.0.0; git checkout -q -b other; commit; git tag v9.0.0; git checkout -q main; commit
expect_version "unreachable tags are ignored" "v1.0.1-dev.1.g$(short)" main

# Version lines: a release branch stays on its line, main moves to the marker.
#
#   main:          A(v2.4.0) - B(v2.5.0-0, branch point) - C - D
#   release/v2.4:                                      \ - E(v2.4.13) - F
new_repo lines
commit; git tag v2.4.0; commit; git tag v2.5.0-0
git branch release/v2.4
commit 2
expect_version "main uses the marker" "v2.5.0-0.dev.2.g$(short)" main
git checkout -q release/v2.4; commit; git tag v2.4.13; commit
expect_version "release/vX.Y keeps its own line" "v2.4.14-dev.1.g$(short)" release/v2.4
expect_version "pull request on release/vX.Y uses the base branch line" "v2.4.14-dev.1.g$(short)" refs/heads/release/v2.4
git checkout -q -b release/v2; git tag v3.0.0-0 HEAD~1
expect_version "release/vX uses its whole major line, not the next major" "v2.5.0-0.dev.2.g$(short)" release/v2
expect_version "feature branch uses every tag" "v3.0.0-0.dev.1.g$(short)" feature/foo
git checkout -q main

# Failures.
new_repo notags
commit
expect_failure "no tag fails" "no SemVer tag" main
git tag v1.0.0
expect_failure "no tag in the line fails" "line of branch 'release/v2.0'" release/v2.0

new_repo shallow-src
commit; git tag v1.0.0; commit 3
git clone -q --depth 1 "file://$WORK/shallow-src" "$WORK/shallow" 2>/dev/null
cd "$WORK/shallow" || exit 1
expect_failure "shallow clone fails" "shallow" main

cd "$WORK" || exit 1
expect_failure "outside a repository fails" "not inside a Git repository" main

# --- mark-version-line --------------------------------------------------------

# run_mark BRANCH [DRY_RUN] -> prints the marker output, returns the script status.
run_mark() {
  local out="$WORK/out.$RANDOM"
  : >"$out"
  MARK_BRANCH=$1 MARK_DEFAULT_BRANCH=main MARK_DRY_RUN=${2:-false} GITHUB_OUTPUT=$out \
    bash "$MARK" 2>"$WORK/stderr" || return $?
  sed -n 's/^marker=//p' "$out"
}

expect_marker() {
  local name=$1 want=$2 branch=$3 dry=${4:-false} got
  got=$(run_mark "$branch" "$dry")
  local status=$?
  if ((status != 0)); then
    ko "$name" "exit $status: $(cat "$WORK/stderr")"
  elif [[ $got != "$want" ]]; then
    ko "$name" "got '$got', want '$want'"
  else
    ok "$name"
  fi
}

# origin is a bare repository; the clone plays the CI checkout.
new_repo mark-src
commit; git tag v2.4.0; commit
POINT=$(git rev-parse HEAD)
git branch release/v2.4
git branch release/v2
commit 2
git checkout -q release/v2.4; commit; git checkout -q main
git clone -q --bare "$WORK/mark-src" "$WORK/mark-origin.git"
git clone -q "$WORK/mark-origin.git" "$WORK/mark"
cd "$WORK/mark" || exit 1

expect_marker "dry run computes the marker" "v2.5.0-0" release/v2.4 true
if git ls-remote --exit-code --tags origin v2.5.0-0 >/dev/null; then ko "dry run pushes nothing"; else ok "dry run pushes nothing"; fi

expect_marker "release/vX.Y marks vX.(Y+1).0-0" "v2.5.0-0" refs/heads/release/v2.4
remote_point=$(git ls-remote origin 'refs/tags/v2.5.0-0^{}' | cut -f1)
if [[ $remote_point == "$POINT" ]]; then ok "marker is on the branch point"; else ko "marker is on the branch point" "got '$remote_point', want '$POINT'"; fi

expect_marker "existing line tag is left alone" "" release/v2.4
expect_marker "release/vX marks v(X+1).0.0-0" "v3.0.0-0" release/v2
expect_marker "non-release branch is ignored" "" feature/foo
expect_marker "releases/ (plural) is ignored" "" releases/v2.4

# Regression: more tags in the next line than fit in a pipe buffer (64 KiB)
# must still be a successful no-op, not a SIGPIPE failure under pipefail.
new_repo mark-many-src
commit; git tag v4.0.0
git branch release/v4.0
commit
head_sha=$(git rev-parse HEAD)
for ((i = 0; i < 20000; i++)); do echo "create refs/tags/v4.1.$i $head_sha"; done | git update-ref --stdin
git clone -q --bare "$WORK/mark-many-src" "$WORK/mark-many-origin.git"
git clone -q "$WORK/mark-many-origin.git" "$WORK/mark-many"
cd "$WORK/mark-many" || exit 1
expect_marker "existing line with many tags is left alone" "" release/v4.0
cd "$WORK/mark" || exit 1

# --- dev-version and mark-version-line together -------------------------------

git fetch -q --tags origin
git checkout -q main
expect_version "main picks up the pushed marker" "v3.0.0-0.dev.2.g$(short)" main

echo
echo "$PASS passed, $FAIL failed"
((FAIL == 0))
