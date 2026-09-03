# go-release.yml

Runs GoReleaser for tagged releases with optional SLSA attestations. Triggered by tag push events.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `runner-profile` | string | `namespace-profile-linux-amd64-4vcpu` | Namespace runner profile |
| `goreleaser-parallelism` | number | `0` | GoReleaser parallelism (0 = default) |
| `enable-docker` | boolean | `true` | Setup GHCR login, QEMU, and Buildx |
| `enable-attestations` | boolean | `false` | Generate SLSA build provenance attestations |
| `nix-extra-flags` | string | `''` | Extra flags for `nix develop` |

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
Release:
  uses: formancehq/ci/.github/workflows/go-release.yml@main
  permissions:
    contents: write
    packages: write
    id-token: write
    attestations: write
  secrets:
    NUMARY_GITHUB_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
    GORELEASER_KEY: ${{ secrets.GORELEASER_KEY }}
```
