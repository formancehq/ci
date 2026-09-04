# setup-nix-pnpm

Installs Nix with flake caching and pnpm store cache for JS/TS repos. Uses `nix-community/cache-nix-action` instead of Namespace caching.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `nix-extra-flags` | `''` | Extra flags for `nix develop` |

## Example

```yaml
- uses: formancehq/ci/actions/setup-nix-pnpm@v1
```
