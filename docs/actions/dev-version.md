# dev-version

Computes a SemVer-valid development version from Git tags, as specified by RFC-0013
(SemVer-Valid Development Versions for Stack Modules):

```text
v<base>-dev.<distance>.g<short-sha>
```

The base tag is the highest SemVer tag reachable from the commit that belongs to the
branch's version line. "Highest" uses SemVer precedence (the same order as
`golang.org/x/mod/semver`), not `git describe` or `sort -V`.

| Branch | Candidate tags |
|--------|----------------|
| `release/vX.Y` | `vX.Y.*` |
| `release/vX` | `vX.*` |
| anything else (`main`, feature branches) | `v*` |

| Base tag | Development version |
|----------|---------------------|
| Stable `vX.Y.Z` | `vX.Y.(Z+1)-dev.N.gSHA` |
| Prerelease `vX.Y.Z-P` (including markers `vX.Y.Z-0`) | `vX.Y.Z-P.dev.N.gSHA` |

`N` is the number of commits since the base tag, so builds of one branch sort in commit
order. Tags that are not `v`-prefixed SemVer without build metadata (`v1.2`, `v1.2.3+meta`,
`pkg/domain/v0.1.0`) are ignored.

The action fails, instead of falling back to a SHA, when the checkout is shallow or when
no candidate tag is reachable. Check out with `fetch-depth: 0`.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `branch` | PR / merge queue base branch, else the pushed ref | Branch whose version line applies |
| `ref` | `HEAD` | Commit to version |
| `working-directory` | `.` | Directory inside the checkout |

## Outputs

| Name | Example | Description |
|------|---------|-------------|
| `version` | `v2.4.2-dev.76.g6399077` | With leading `v`: image tag, `deploy-staging` tag |
| `version-number` | `2.4.2-dev.76.g6399077` | Without `v`: GoReleaser's `DEV_VERSION` |
| `base-tag` | `v2.4.1` | Tag the version derives from |
| `distance` | `76` | Commits since `base-tag` |
| `short-sha` | `6399077` | Abbreviated commit hash |

## Example

```yaml
- uses: namespacelabs/nscloud-checkout-action@v9
  with:
    fetch-depth: 0
- id: dev-version
  uses: formancehq/ci/actions/dev-version@v1
- run: goreleaser release --nightly --clean
  env:
    DEV_VERSION: ${{ steps.dev-version.outputs.version-number }}
```

`go-build.yml` runs it for you with `dev-version: true`.

## Tests

`tests/dev-version/run.sh` (bash and git only) covers precedence, version lines, markers,
invalid and unreachable tags, missing tags, and shallow clones.
