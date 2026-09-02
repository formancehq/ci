# Migration guide

## What every repo needs

### 1. Workflow name

Set `name: Default` at the top of `.github/workflows/main.yml`. GitHub constructs check names as `WorkflowName / CallerJobName / CalleeJobName`, so the org ruleset expects `Default / Dirty / Dirty` and `Default / Tests / Test`.

### 2. PR event types

Add `edited` to `pull_request.types` so the PR title check re-runs when a title is corrected:

```yaml
on:
  merge_group:
  push:
    branches: [main]
  pull_request:
    types: [assigned, opened, synchronize, reopened, labeled, edited]
```

### 3. Dirty job

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@main
  secrets:
    GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```

See [go-dirty.yml docs](workflows/go-dirty.md) for available inputs (`runner-profile`, `pre-commit-target`, `command`).

### 4. Tests job

```yaml
Tests:
  uses: formancehq/ci/.github/workflows/go-test.yml@main
```

See [go-test.yml docs](workflows/go-test.md) for inputs (`runner-profile`, `command`, `enable-codecov`).

### 5. PR title validation

```yaml
PR:
  if: github.event_name == 'pull_request'
  uses: formancehq/ci/.github/workflows/go-pr.yml@main
  permissions:
    pull-requests: read
    statuses: write
```

### 6. Verify

Open a PR. GitHub should show `Default / Dirty / Dirty` and `Default / Tests / Test`. If the repo has both checks, ensure it is listed in `ruleset_ci_repositories` in `infra2/terraform/github/rulesets.tf`.

## Build and release (optional)

Repos that build Docker images via GoReleaser:

```yaml
GoReleaser:
  needs: [Dirty]
  uses: formancehq/ci/.github/workflows/go-build.yml@main
  with:
    build-condition: main-and-label
    build-label: build-images
  secrets:
    NUMARY_GITHUB_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
    GORELEASER_KEY: ${{ secrets.GORELEASER_KEY }}
```

See [go-build.yml docs](workflows/go-build.md) and [go-release.yml docs](workflows/go-release.md).

## Deploy (optional)

Repos that deploy to staging via ArgoCD use the `deploy-staging` composite action. See [deploy-staging docs](actions/deploy-staging.md).

## Parallel test jobs

Repos that split tests into parallel sub-jobs (e.g. unit + integration) cannot use `go-test.yml` for the aggregate: reusable workflow jobs cannot depend on inline jobs in the same file.

Keep the sub-jobs inline, each uploading a coverage artifact. Use `go-test-coverage.yml` for the aggregate:

```yaml
TestsUnit:
  name: "Tests (Unit)"
  runs-on: namespace-profile-linux-amd64-4vcpu
  steps:
    - uses: namespacelabs/nscloud-checkout-action@v9
      with: { fetch-depth: 0, dissociate: true }
    - uses: formancehq/ci/actions/setup-nix@main
      with: { git-private-token: "${{ secrets.NUMARY_GITHUB_TOKEN }}" }
    - run: nix develop --impure --command just tests-unit
    - uses: actions/upload-artifact@v7
      with: { name: coverage-unit-report, path: ./coverage/coverage_unit.txt }

Tests:
  needs: [TestsUnit, TestsIntegration]
  uses: formancehq/ci/.github/workflows/go-test-coverage.yml@main
  with:
    coverage-files: coverage/coverage_unit.txt,coverage/coverage_integration.txt
    coverage-pattern: coverage-*
    post-download-command: just coverage
  secrets:
    CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
    GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```

## Non-Go repos

For JS/TS repos without a Go toolchain in their Nix shell, pass `skip-go: true` and optionally `pnpm-cache: true`:

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@main
  with:
    command: "pnpm run qa"
    pnpm-cache: true
    skip-go: true
  secrets:
    GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```