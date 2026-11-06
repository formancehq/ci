#!/usr/bin/env bash
# Computes a SemVer-valid development version from Git tags, as specified by
# RFC-0013 (SemVer-Valid Development Versions for Stack Modules):
#
#   v<base>-dev.<distance>.g<short-sha>
#
# The base tag is the highest SemVer tag (by SemVer precedence, not `sort -V`)
# that is reachable from the commit and belongs to the branch's version line:
#
#   release/vX.Y  ->  vX.Y.*
#   release/vX    ->  vX.*
#   anything else ->  v*
#
#   stable base     vX.Y.Z    ->  vX.Y.(Z+1)-dev.N.gSHA
#   prerelease base vX.Y.Z-P  ->  vX.Y.Z-P.dev.N.gSHA
#
# Environment:
#   DEV_VERSION_BRANCH  branch whose version line applies (refs/heads/ prefix allowed)
#   DEV_VERSION_REF     commit to version (default: HEAD)
#   GITHUB_OUTPUT       file receiving the outputs (default: stdout)
#
# Outputs: version, version-number, base-tag, distance, short-sha.
#
# The script can be sourced to reuse the SemVer helpers (see tests/dev-version).

set -euo pipefail
export LC_ALL=C

_NUM='(0|[1-9][0-9]*)'
_ALNUM='[0-9]*[A-Za-z-][0-9A-Za-z-]*'
_PRE_ID="(${_NUM}|${_ALNUM})"
# SemVer 2.0.0 with a mandatory `v` prefix and no build metadata.
SEMVER_RE="^v${_NUM}\.${_NUM}\.${_NUM}(-${_PRE_ID}(\.${_PRE_ID})*)?$"

die() {
  echo "::error title=dev-version::$*" >&2
  exit 1
}

is_semver() {
  [[ $1 =~ $SEMVER_RE ]]
}

# _cmp_num A B: compare two non-negative integers of any length (no leading
# zeros). Sets CMP to -1, 0 or 1.
_cmp_num() {
  if ((${#1} != ${#2})); then
    if ((${#1} < ${#2})); then CMP=-1; else CMP=1; fi
  elif [[ $1 == "$2" ]]; then
    CMP=0
  elif [[ $1 < $2 ]]; then
    CMP=-1
  else
    CMP=1
  fi
}

# _inc_num N: add one to a non-negative decimal integer of any length, as a
# string, so patches beyond the shell's 64-bit range do not overflow. Sets REPLY.
_inc_num() {
  local n=$1 i=$((${#1} - 1)) zeros=""
  while ((i >= 0)) && [[ ${n:i:1} == 9 ]]; do
    zeros="${zeros}0"
    i=$((i - 1))
  done
  if ((i < 0)); then
    REPLY="1${zeros}"
  else
    REPLY="${n:0:i}$((${n:i:1} + 1))${zeros}"
  fi
}

# _cmp_ident A B: compare two prerelease identifiers (SemVer 11.4.1-11.4.3).
_cmp_ident() {
  local a_num=false b_num=false
  [[ $1 =~ ^[0-9]+$ ]] && a_num=true
  [[ $2 =~ ^[0-9]+$ ]] && b_num=true
  if $a_num && $b_num; then
    _cmp_num "$1" "$2"
  elif $a_num; then
    CMP=-1 # numeric identifiers have lower precedence than alphanumeric ones
  elif $b_num; then
    CMP=1
  elif [[ $1 == "$2" ]]; then
    CMP=0
  elif [[ $1 < $2 ]]; then # ASCII order, LC_ALL=C
    CMP=-1
  else
    CMP=1
  fi
}

# semver_cmp A B: compare two versions accepted by is_semver by SemVer
# precedence. Sets CMP to -1, 0 or 1.
semver_cmp() {
  local a="${1#v}" b="${2#v}"
  local a_core="${a%%-*}" b_core="${b%%-*}"
  local a_pre="" b_pre=""
  [[ $a == *-* ]] && a_pre="${a#*-}"
  [[ $b == *-* ]] && b_pre="${b#*-}"

  local -a ac bc
  IFS=. read -r -a ac <<<"$a_core"
  IFS=. read -r -a bc <<<"$b_core"
  local i
  for i in 0 1 2; do
    _cmp_num "${ac[i]}" "${bc[i]}"
    ((CMP != 0)) && return 0
  done

  # A version without prerelease has higher precedence than one with.
  if [[ -z $a_pre && -z $b_pre ]]; then CMP=0; return 0; fi
  if [[ -z $a_pre ]]; then CMP=1; return 0; fi
  if [[ -z $b_pre ]]; then CMP=-1; return 0; fi

  local -a ap bp
  IFS=. read -r -a ap <<<"$a_pre"
  IFS=. read -r -a bp <<<"$b_pre"
  local n=${#ap[@]}
  ((${#bp[@]} < n)) && n=${#bp[@]}
  for ((i = 0; i < n; i++)); do
    _cmp_ident "${ap[i]}" "${bp[i]}"
    ((CMP != 0)) && return 0
  done
  # A larger set of identifiers has higher precedence when all preceding ones are equal.
  _cmp_num "${#ap[@]}" "${#bp[@]}"
}

# line_prefix BRANCH: print the tag prefix of the branch's version line.
line_prefix() {
  local branch="${1#refs/heads/}"
  if [[ $branch =~ ^release/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    echo "v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}."
  elif [[ $branch =~ ^release/v(0|[1-9][0-9]*)$ ]]; then
    echo "v${BASH_REMATCH[1]}."
  else
    echo "v"
  fi
}

main() {
  local branch="${DEV_VERSION_BRANCH:-}"
  local ref="${DEV_VERSION_REF:-HEAD}"
  [[ -n $ref ]] || ref=HEAD
  branch="${branch#refs/heads/}"

  git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a Git repository"
  local commit
  commit=$(git rev-parse --verify --quiet "${ref}^{commit}") || die "'${ref}' is not a commit"

  if [[ $(git rev-parse --is-shallow-repository) != false ]]; then
    die "the checkout is shallow: check out the full history (fetch-depth: 0) so tags and commit distance are available"
  fi

  local prefix
  prefix=$(line_prefix "$branch")

  local base="" tag
  while IFS= read -r tag; do
    is_semver "$tag" || continue
    if [[ -z $base ]]; then
      base=$tag
    else
      semver_cmp "$tag" "$base"
      ((CMP > 0)) && base=$tag
    fi
  done < <(git tag --merged "$commit" --list "${prefix}[0-9]*")

  if [[ -z $base ]]; then
    if [[ $prefix == v ]]; then
      die "no SemVer tag (vX.Y.Z[-prerelease]) is reachable from ${commit}; are tags fetched?"
    fi
    die "no SemVer tag in the ${prefix}* line of branch '${branch}' is reachable from ${commit}; push the line's marker tag (e.g. ${prefix}0-0 for a minor line, ${prefix}0.0-0 for a major line) or a release tag first"
  fi

  local distance short
  distance=$(git rev-list --count "${base}..${commit}")
  short=$(git rev-parse --short=7 "$commit")

  local version
  if [[ $base == *-* ]]; then
    version="${base}.dev.${distance}.g${short}"
  else
    local major minor patch
    IFS=. read -r major minor patch <<<"${base#v}"
    _inc_num "$patch"
    version="v${major}.${minor}.${REPLY}-dev.${distance}.g${short}"
  fi

  is_semver "$version" || die "computed version '${version}' is not valid SemVer"

  echo "dev-version: branch='${branch}' line='${prefix}*' base=${base} distance=${distance} -> ${version}" >&2

  {
    echo "version=${version}"
    echo "version-number=${version#v}"
    echo "base-tag=${base}"
    echo "distance=${distance}"
    echo "short-sha=${short}"
  } >>"${GITHUB_OUTPUT:-/dev/stdout}"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
