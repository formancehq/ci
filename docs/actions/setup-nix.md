# setup-nix

Installs Nix, configures git for private `formancehq` repos, extracts Go environment, and sets up Namespace runner caching for Go modules and build artifacts.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `nscloud-cache` | `'true'` | Enable Namespace Go and lint caching |
| `cache-nix-store` | `''` | Cache /nix store (defaults to `nscloud-cache` value) |
| `cache-golangci-lint` | `'true'` | Include `~/.cache/golangci-lint` in cache |
| `nix-extra-flags` | `''` | Extra flags for `nix develop` |
| `git-private-token` | `''` | GitHub PAT for private repo access (also sets `GOPRIVATE`) |
| `skip-go` | `'false'` | Skip Go env extraction and caching |

## Example

```yaml
- uses: formancehq/ci/actions/setup-nix@v1
  with:
    git-private-token: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```
