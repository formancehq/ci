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

## Constraints

- Do not create a GitHub Release on a bare major tag (`v1`). Releases belong to `vX.Y.Z`
  tags; `v1` is a moving pointer and must stay mutable.
- Tag protection rules and tag immutability rulesets must exclude the bare major tags,
  otherwise the force-push in `major-tag.yml` fails.

## Consumer trade-off

`@v1` is mutable by design: fixes reach every consumer repository without a PR in each one,
but every consumer also executes whatever commit `v1` points at today. Repositories that
need determinism pin the commit instead and let Dependabot bump it:

```yaml
uses: formancehq/ci/.github/workflows/go-release.yml@c7e7acd # v1.0.1
```
