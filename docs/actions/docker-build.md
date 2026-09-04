# docker-build

Builds and pushes Docker images to GHCR with configurable buildx backend.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `image` | *(required)* | Full image name (e.g. `ghcr.io/formancehq/connectivity`) |
| `token` | *(required)* | GitHub token for GHCR |
| `dockerfile` | `Dockerfile` | Path to Dockerfile |
| `context` | `.` | Docker build context |
| `platforms` | `linux/amd64,linux/arm64` | Target platforms |
| `push` | `'false'` | Push the image |
| `tag-rules` | SHA + latest | `docker/metadata-action` tag rules |
| `tags` | `''` | Explicit tags (overrides `tag-rules`) |
| `build-args` | `''` | Docker build args (KEY=VALUE, one per line) |
| `target` | `''` | Docker build target stage |
| `login-username` | `github.actor` | GHCR login username |
| `buildx-setup` | `qemu` | Buildx backend: `qemu`, `namespace`, or `none` |
| `outputs` | `''` | BuildKit output mode (e.g. `type=cacheonly` for PR builds) |

## Outputs

| Name | Description |
|------|-------------|
| `digest` | Image digest |
| `metadata` | Build metadata |
| `tags` | Generated tags |

## Example

```yaml
- uses: formancehq/ci/actions/docker-build@v1
  with:
    image: ghcr.io/formancehq/my-service
    token: ${{ secrets.NUMARY_GITHUB_TOKEN }}
    push: true
    buildx-setup: namespace
```
