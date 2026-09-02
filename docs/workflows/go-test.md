# go-test.yml

Runs tests inside a Nix devshell with optional Codecov upload.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `runner-profile` | string | `namespace-profile-linux-amd64-8vcpu` | Namespace runner profile |
| `test-target` | string | `tests` | Just target for running tests |
| `extra-test-targets` | string | `''` | Space-separated additional just targets |
| `command` | string | `''` | Raw shell command (overrides `test-target`) |
| `enable-codecov` | boolean | `false` | Upload coverage to Codecov |
| `coverage-files` | string | `''` | Comma-separated coverage file paths |
| `nix-extra-flags` | string | `''` | Extra flags for `nix develop` |
| `pnpm-cache` | boolean | `false` | Enable pnpm store caching |
| `skip-go` | boolean | `false` | Skip Go environment extraction |

## Secrets

| Name | Required | Description |
|------|----------|-------------|
| `SPEAKEASY_API_KEY` | No | Speakeasy SDK generation |
| `NUMARY_GITHUB_TOKEN` | No | Exposed as `GITHUB_TOKEN` in the test step |
| `CODECOV_TOKEN` | No | Codecov upload token |
| `GIT_PRIVATE_TOKEN` | No | Private `formancehq` repo access |

## Example

```yaml
Tests:
  uses: formancehq/ci/.github/workflows/go-test.yml@main
  with:
    runner-profile: namespace-profile-linux-amd64-4vcpu
    enable-codecov: true
    coverage-files: ./coverage.txt
  secrets:
    CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
    GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```
