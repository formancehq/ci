# go-test-coverage.yml

Aggregates coverage artifacts from parallel test sub-jobs and uploads to Codecov. Use this when your repo splits tests into multiple jobs (e.g. unit + integration) that each upload a coverage artifact.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `runner-profile` | string | `namespace-profile-linux-amd64-2vcpu` | Namespace runner profile |
| `coverage-files` | string | `''` | Comma-separated coverage file paths for Codecov |
| `coverage-pattern` | string | `coverage-*` | Artifact name pattern to download |
| `post-download-command` | string | `''` | Command to run after downloading (e.g. `just coverage`) |
| `nix-extra-flags` | string | `''` | Extra flags for `nix develop` |

## Secrets

| Name | Required | Description |
|------|----------|-------------|
| `CODECOV_TOKEN` | No | Codecov upload token |
| `GIT_PRIVATE_TOKEN` | No | Private `formancehq` repo access (needed when `post-download-command` triggers Nix setup) |

## Example

```yaml
TestsUnit:
  name: "Tests (Unit)"
  runs-on: namespace-profile-linux-amd64-4vcpu
  steps:
    # ... run tests, upload coverage artifact ...
    - uses: actions/upload-artifact@v7
      with:
        name: coverage-unit-report
        path: ./coverage/coverage_unit.txt

TestsIntegration:
  name: "Tests (Integration)"
  runs-on: namespace-profile-linux-amd64-8vcpu
  steps:
    # ... run tests, upload coverage artifact ...
    - uses: actions/upload-artifact@v7
      with:
        name: coverage-integration-report
        path: ./coverage/coverage_integration.txt

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
