# setup-release

Extends `setup-nix` with GHCR login, QEMU, and Namespace Buildx for container builds.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `token` | *(required)* | GitHub PAT for GHCR login |
| `nscloud-cache` | `'true'` | Enable Namespace caching |
| `cache-golangci-lint` | `'true'` | Include golangci-lint cache |
| `nix-extra-flags` | `''` | Extra flags for `nix develop` |
| `git-private-token` | `''` | GitHub PAT for private repo access |

## Example

```yaml
- uses: formancehq/ci/actions/setup-release@v1
  with:
    token: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```
