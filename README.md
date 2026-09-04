# ci

Centralized reusable GitHub Actions workflows and composite actions for Formance repositories. Provides shared CI pipelines for validation, testing, building, releasing, and deploying Go and JS/TS services.

## Check naming

All caller workflows must use `name: Default`. GitHub Actions constructs check run names for reusable workflows as:

```
CallerJobName / CalleeJobName
```

For example, a job named `Dirty` calling `go-dirty.yml` (which has a job named `Dirty`) produces `Dirty / Dirty`. The org rulesets require `Dirty / Dirty` and `Tests / Test`.

The GitHub UI displays checks with the workflow name as a visual prefix (`Default / Dirty / Dirty (pull_request)`), but the actual check context used for ruleset matching is `Dirty / Dirty` — without the workflow name or event type.

## Workflows

| Workflow | Description | Docs |
|----------|-------------|------|
| `go-pr.yml` | PR title validation (Conventional Commits) | [docs](docs/workflows/go-pr.md) |
| `go-dirty.yml` | Pre-commit + working tree check | [docs](docs/workflows/go-dirty.md) |
| `go-test.yml` | Test runner + optional Codecov | [docs](docs/workflows/go-test.md) |
| `go-test-coverage.yml` | Coverage aggregation for parallel test jobs | [docs](docs/workflows/go-test-coverage.md) |
| `go-build.yml` | GoReleaser CI build + GHCR | [docs](docs/workflows/go-build.md) |
| `go-release.yml` | GoReleaser tagged release + GHCR | [docs](docs/workflows/go-release.md) |
| `go-validate.yml` | Composite of pr + dirty + test | -- |
| `go-codeql.yml` | CodeQL static analysis for Go | -- |

## Actions

| Action | Description | Docs |
|--------|-------------|------|
| `setup-nix` | Nix + Go env + Namespace caching | [docs](docs/actions/setup-nix.md) |
| `setup-release` | setup-nix + GHCR + QEMU + Buildx | [docs](docs/actions/setup-release.md) |
| `setup-nix-pnpm` | Nix + pnpm cache for JS/TS repos | [docs](docs/actions/setup-nix-pnpm.md) |
| `deploy-staging` | Tailscale OIDC + ArgoCD deploy | [docs](docs/actions/deploy-staging.md) |
| `docker-build` | Docker build + push with configurable buildx | [docs](docs/actions/docker-build.md) |
| `docker-manifest` | Multi-arch manifest from per-arch images | [docs](docs/actions/docker-manifest.md) |

## Quick start

A typical Go service needs only this in `.github/workflows/main.yml`:

```yaml
name: Default
on:
  merge_group:
  push:
    branches:
      - main
  pull_request:
    types: [assigned, opened, synchronize, reopened, labeled, edited]

jobs:
  PR:
    if: github.event_name == 'pull_request'
    uses: formancehq/ci/.github/workflows/go-pr.yml@v1
    permissions:
      pull-requests: read
      statuses: write

  Dirty:
    uses: formancehq/ci/.github/workflows/go-dirty.yml@v1
    secrets:
      GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}

  Tests:
    uses: formancehq/ci/.github/workflows/go-test.yml@v1

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
