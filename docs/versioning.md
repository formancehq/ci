# Versioning

Callers reference this repository with a git ref:

```yaml
uses: formancehq/ci/.github/workflows/go-release.yml@v1
```

GitHub resolves that ref at run time and applies no semver logic: `v1` is a plain tag
that must be moved to each new `v1.x.y` release for callers to pick up fixes.

## Release flow

1. Push an annotated `vX.Y.Z` tag on `main`.
2. `major-tag.yml` fires on that tag and force-moves the matching `vX` tag to the same commit.
3. Callers on `@vX` use the new commit on their next run -- no change required on their side.

The workflow only matches `v[0-9]+.[0-9]+.[0-9]+`, so pre-releases such as `v1.2.0-rc1`
never move the major tag.

Major tag updates are forward-only: the tag moves only when its current commit is an
ancestor of the released commit. A run that would move it backward -- two releases finishing
out of order, or a hotfix tagged on an older line -- logs a warning and leaves the tag alone.
Move it by hand if that hotfix really should own the major tag.

The push itself is a compare-and-swap (`--force-with-lease` against the tag object read at
the start of the run), so a release that lands between the check and the write is rejected
rather than overwritten; the run re-reads and retries. Runs are deliberately not placed in a
concurrency group: a shared group cancels pending runs and would leave a major tag stale.

## Constraints

- Do not create a GitHub Release on a bare major tag (`v1`). Releases belong to `vX.Y.Z`
  tags; `v1` is a moving pointer and must stay mutable.
- Tag protection rules and tag immutability rulesets must exclude the bare major tags,
  otherwise the force-push in `major-tag.yml` fails.

## What pinning does and does not freeze

`@v1` is mutable by design: fixes reach every consumer repository without a PR in each one,
but every consumer also executes whatever commit `v1` points at today.

Pinning a full commit SHA freezes the reusable workflow file:

```yaml
uses: formancehq/ci/.github/workflows/go-release.yml@c7e7acd91ea6c0b72e4d39501f61ed4ec10f3f8f # v1.0.1
```

A full 40-character SHA is required -- GitHub does not resolve abbreviated revisions in
`uses:`.

It does not freeze everything the workflow runs. The reusable workflows call the composite
actions in this repository at `@v1`:

```yaml
uses: formancehq/ci/actions/setup-nix@v1
```

At release time, `major-tag.yml` stamps these `@v1` refs to the exact point release
(`@v1.0.3`), so a SHA-pinned consumer gets fully frozen action code for that release.
Consumers on the floating `@v1` tag always get the latest point release's stamped actions.
