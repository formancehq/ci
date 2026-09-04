# docker-manifest

Creates and pushes a multi-arch Docker manifest from per-architecture images.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `image` | *(required)* | Full image name without tag |
| `tag` | *(required)* | Manifest tag |
| `arch-tags` | *(required)* | Per-architecture image references (one per line) |
| `token` | *(required)* | GitHub token for GHCR |
| `login-username` | `github.actor` | GHCR login username |

## Example

```yaml
- uses: formancehq/ci/actions/docker-manifest@v1
  with:
    image: ghcr.io/formancehq/console-v3
    tag: ${{ github.sha }}
    arch-tags: |
      ghcr.io/formancehq/console-v3:${{ github.sha }}_linux_amd64
      ghcr.io/formancehq/console-v3:${{ github.sha }}_linux_arm64
    token: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```
