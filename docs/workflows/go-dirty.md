# go-dirty.yml

Runs pre-commit validation inside a Nix devshell and asserts the working tree is clean afterward.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `runner-profile` | string | `namespace-profile-linux-amd64-4vcpu` | Namespace runner profile |
| `pre-commit-target` | string | `pre-commit` | Just target for validation |
| `command` | string | `''` | Raw shell command (overrides `pre-commit-target`) |
| `nix-extra-flags` | string | `''` | Extra flags for `nix develop` |
| `cache-nix-store` | string | `'true'` | Cache /nix store via Namespace |
| `pnpm-cache` | boolean | `false` | Enable pnpm store caching |
| `skip-go` | boolean | `false` | Skip Go environment extraction (for non-Go repos) |

## Secrets

| Name | Required | Description |
|------|----------|-------------|
| `SPEAKEASY_API_KEY` | No | Speakeasy SDK generation |
| `GIT_PRIVATE_TOKEN` | No | Private `formancehq` repo access |
| `NUMARY_GITHUB_TOKEN` | No | Exposed as `GITHUB_TOKEN` in the pre-commit step |

## Example

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@main
  with:
    runner-profile: namespace-profile-linux-amd64-2vcpu
  secrets:
    SPEAKEASY_API_KEY: ${{ secrets.SPEAKEASY_API_KEY }}
    GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```

For JS/TS repos:

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
