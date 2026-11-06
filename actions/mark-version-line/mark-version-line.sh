#!/usr/bin/env bash
# Tags the branch point of a release branch with the marker of the next
# version line, as specified by RFC-0013 (Marking version lines):
#
#   release/vX.Y  ->  vX.(Y+1).0-0
#   release/vX    ->  v(X+1).0.0-0
#
# The branch point is the merge base of the release branch and the default
# branch. Nothing is tagged when the branch name matches neither form, when
# the branches share no history, or when a tag of the marker's line already
# exists.
#
# Environment:
#   MARK_BRANCH          release branch (refs/heads/ prefix allowed)
#   MARK_DEFAULT_BRANCH  default branch of the repository (e.g. main)
#   MARK_REMOTE          remote to read branches from and push to (default: origin)
#   MARK_DRY_RUN         "true" to compute without tagging or pushing
#   GITHUB_OUTPUT        file receiving the outputs (default: stdout)
#
# Outputs: marker (empty when nothing was tagged), branch-point, pushed.

set -euo pipefail
export LC_ALL=C

# Shared SemVer helpers (_inc_num, is_semver). Both actions ship in the same
# repository, so the sibling script is always present next to this one.
# shellcheck source=SCRIPTDIR/../dev-version/dev-version.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../dev-version/dev-version.sh"

die() {
  echo "::error title=mark-version-line::$*" >&2
  exit 1
}

output() {
  {
    echo "marker=${1}"
    echo "branch-point=${2}"
    echo "pushed=${3}"
  } >>"${GITHUB_OUTPUT:-/dev/stdout}"
}

skip() {
  echo "::notice title=mark-version-line::$*" >&2
  output "" "" false
  exit 0
}

branch="${MARK_BRANCH:-}"
branch="${branch#refs/heads/}"
default_branch="${MARK_DEFAULT_BRANCH:-}"
remote="${MARK_REMOTE:-origin}"
dry_run="${MARK_DRY_RUN:-false}"

[[ -n $branch ]] || die "MARK_BRANCH is empty"
[[ -n $default_branch ]] || die "MARK_DEFAULT_BRANCH is empty"

if [[ $branch =~ ^release/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  major=${BASH_REMATCH[1]}
  _inc_num "${BASH_REMATCH[2]}" # decimal string: no 64-bit overflow
  minor=$REPLY
  marker="v${major}.${minor}.0-0"
  line="v${major}.${minor}."
elif [[ $branch =~ ^release/v(0|[1-9][0-9]*)$ ]]; then
  _inc_num "${BASH_REMATCH[1]}"
  major=$REPLY
  marker="v${major}.0.0-0"
  line="v${major}."
else
  skip "'${branch}' is neither release/vX.Y nor release/vX; no marker to create"
fi

is_semver "$marker" || die "computed marker '${marker}' is not valid SemVer"

git fetch --quiet --tags "$remote" \
  "+refs/heads/${branch}:refs/remotes/${remote}/${branch}" \
  "+refs/heads/${default_branch}:refs/remotes/${remote}/${default_branch}" ||
  die "cannot fetch '${branch}' and '${default_branch}' from ${remote}"

if [[ $(git rev-parse --is-shallow-repository) != false ]]; then
  die "the checkout is shallow: check out the full history (fetch-depth: 0)"
fi

# Read the whole list before picking a tag: closing a pipe early (head -n 1)
# makes git die of SIGPIPE once the list exceeds the pipe buffer, which fails
# the script under pipefail.
existing=$(git tag --list "${line}[0-9]*")
existing=${existing%%$'\n'*}
if [[ -n $existing ]]; then
  skip "the ${line}* line already has a tag (${existing}); ${marker} is not needed"
fi

point=$(git merge-base "refs/remotes/${remote}/${branch}" "refs/remotes/${remote}/${default_branch}") ||
  skip "'${branch}' shares no history with '${default_branch}'; no marker to create"

echo "mark-version-line: ${branch} -> ${marker} on ${point} (merge base with ${default_branch})" >&2

if [[ $dry_run == true ]]; then
  echo "::notice title=mark-version-line::dry run: would tag ${point} as ${marker}" >&2
  output "$marker" "$point" false
  exit 0
fi

git -c user.name="${GIT_AUTHOR_NAME:-github-actions[bot]}" \
  -c user.email="${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}" \
  tag -a "$marker" "$point" \
  -m "Start of the ${line}x version line (cut of ${branch}), see RFC-0013"
git push "$remote" "refs/tags/${marker}"

echo "::notice title=mark-version-line::tagged ${point} as ${marker}" >&2
output "$marker" "$point" true
