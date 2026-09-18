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
| `working-directory` | string | `.` | Directory holding the justfile whose `release` recipe runs GoReleaser |

`nix develop` always resolves the dev shell from the repository root, and only
`just` moves into `working-directory`. A monorepo can therefore release one
project per job while declaring GoReleaser once, in the root flake. Artifact
verification and attestations read `<working-directory>/dist`.

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
  uses: formancehq/ci/.github/workflows/go-release.yml@v1
  permissions:
    contents: write
    packages: write
    id-token: write
    attestations: write
  secrets:
    NUMARY_GITHUB_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
    GORELEASER_KEY: ${{ secrets.GORELEASER_KEY }}
```

## Example: one release job per project

```yaml
Release:
  strategy:
    matrix:
      project: [., misc/operator, misc/connectivity-api]
  uses: formancehq/ci/.github/workflows/go-release.yml@v1
  with:
    working-directory: ${{ matrix.project }}
  permissions:
    contents: write
    packages: write
    id-token: write
    attestations: write
  secrets:
    NUMARY_GITHUB_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
    GORELEASER_KEY: ${{ secrets.GORELEASER_KEY }}
```

Each project directory carries its own `justfile` with a `release` recipe and its
own `.goreleaser.yml`. When several jobs publish to the same tag, create the
GitHub release once before the matrix (for example as a draft) and let each
GoReleaser config keep it (`release.mode: keep-existing`).
