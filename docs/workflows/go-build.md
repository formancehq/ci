# go-build.yml

Runs GoReleaser CI build with optional GHCR login and multi-arch support. Conditionally triggers based on branch, labels, or both.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `runner-profile` | string | `namespace-profile-linux-amd64-4vcpu` | Namespace runner profile |
| `build-target` | string | `release-ci` | Just target for the build |
| `goreleaser-parallelism` | number | `0` | GoReleaser parallelism (0 = default) |
| `build-condition` | string | `main-and-label` | When to run: `always`, `main-only`, `label-only`, `main-and-label` |
| `build-label` | string | `build-images` | PR label that triggers the build |
| `build-extra-label` | string | `''` | Additional PR label that triggers the build |
| `enable-docker` | boolean | `true` | Setup GHCR login, QEMU, and Buildx |
| `nix-extra-flags` | string | `''` | Extra flags for `nix develop` |
| `dev-version` | boolean | `false` | Compute a development version with [`dev-version`](../actions/dev-version.md) and pass it to the build as `DEV_VERSION` |

## Outputs

| Name | Description |
|------|-------------|
| `version` | Development version with a leading `v` (`v2.4.2-dev.76.g6399077`). Empty unless `dev-version` is enabled and the build ran |
| `version-number` | Same, without the leading `v` |

## Secrets

| Name | Required | Description |
|------|----------|-------------|
| `NUMARY_GITHUB_TOKEN` | **Yes** | GHCR login and `GITHUB_TOKEN` for GoReleaser |
| `SPEAKEASY_API_KEY` | No | Speakeasy SDK generation |
| `FURY_TOKEN` | No | Gemfury package registry |
| `GORELEASER_KEY` | No | GoReleaser Pro license |
| `GIT_PRIVATE_TOKEN` | No | Private `formancehq` repo access |

## Example

```yaml
GoReleaser:
  needs: [Dirty]
  uses: formancehq/ci/.github/workflows/go-build.yml@v1
  with:
    build-condition: main-and-label
    build-label: build-images
  secrets:
    NUMARY_GITHUB_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
    GORELEASER_KEY: ${{ secrets.GORELEASER_KEY }}
```

## Development versions (RFC-0013)

With `dev-version: true`, the build gets `DEV_VERSION` (no leading `v`) in its environment.
The GoReleaser configuration uses it for nightly builds:

```yaml
nightly:
  version_template: >-
    {{ if index .Env "DEV_VERSION" }}{{ .Env.DEV_VERSION }}{{ else }}{{ .FullCommit }}{{ end }}
```

Pass the `version` output to `deploy-staging` so staging gets a SemVer version instead of
the SHA:

```yaml
GoReleaser:
  uses: formancehq/ci/.github/workflows/go-build.yml@v1
  with:
    dev-version: true
  # ...

Deploy:
  needs: [GoReleaser]
  steps:
    - uses: formancehq/ci/actions/deploy-staging@v1
      with:
        component: payments
        tag: ${{ needs.GoReleaser.outputs.version }}
```
