# deploy-staging

Connects to Tailscale via OIDC and deploys to staging via ArgoCD CLI.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `component` | `''` | Component name (for default parameter pattern) |
| `tag` | *(required)* | Image tag to deploy (typically `github.sha`) |
| `auth-token` | *(required)* | ArgoCD auth token |
| `application` | `staging-eu-west-1-hosting-regions` | ArgoCD application name |
| `parameter` | `''` | ArgoCD parameter(s), one per line (overrides default component pattern) |
| `source-position` | `''` | ArgoCD `--source-position` value |
| `ts-oauth-client-id` | *(required)* | Tailscale OIDC client ID |
| `ts-audience` | *(required)* | Tailscale OIDC audience |
| `ts-tags` | *(required)* | Tailscale tags |
| `ts-version` | `''` | Tailscale version |
| `ts-args` | `''` | Tailscale extra args |
| `ts-retry` | `''` | Tailscale retry count |
| `ts-timeout` | `''` | Tailscale timeout |
| `ts-ping` | `''` | Tailscale ping target |
| `skip-sync` | `'false'` | Skip ArgoCD sync (for chaining multiple `app set` calls) |
| `skip-tailscale` | `'false'` | Skip Tailscale setup (for chaining multiple deploys) |

## Example

```yaml
- uses: formancehq/ci/actions/deploy-staging@v1
  with:
    component: payments
    tag: ${{ github.sha }}
    auth-token: ${{ secrets.ARGOCD_REGION_AUTH_TOKEN }}
    ts-oauth-client-id: ${{ secrets.TS_OIDC_OAUTH_CLIENT_ID }}
    ts-audience: ${{ secrets.TS_OIDC_AUDIENCE }}
    ts-tags: ${{ vars.TS_TAGS }}
    ts-version: ${{ vars.TS_VERSION }}
    ts-args: ${{ vars.TS_ARGS }}
    ts-retry: ${{ vars.TS_RETRY }}
    ts-timeout: ${{ vars.TS_TIMEOUT }}
    ts-ping: ${{ vars.TS_PING }}
```
