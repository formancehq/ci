# Deprecation and rollback policy

## Version contract

`formancehq/ci` uses semantic versioning with a floating major tag:

- **`v1`** — floating tag, always points at the latest `v1.x.y` release. This is what repos pin to.
- **`v1.x.y`** — immutable point release. Use only when you need to freeze a known-good version.
- **`@main`** — development branch, unstable. Do not use in production workflows.

### Version lifecycle

| Phase | Duration | What it means |
|-------|----------|---------------|
| Active | Current major | New features, bug fixes, security patches |
| Maintenance | 3 months after next major | Security and critical bug fixes only |
| End of life | After maintenance | No fixes, no support, remove at your convenience |

When a new major (`v2`) ships, `v1` enters maintenance. Repos have 3 months to migrate before `v1` reaches end of life.

Breaking changes (input renames, removed features, changed check names) only happen across major versions.

## Renovate auto-bump

Every migrated repo has a Renovate config that watches `formancehq/ci` and opens PRs when a new version is tagged. Renovate pins to `@v1`, so patch and minor updates land automatically within the major.

If a Renovate PR breaks CI, close it and pin to the last known-good `v1.x.y` until the issue is fixed upstream.

## Rolling back a repo to local workflows

If a shared workflow breaks and the fix can't wait:

### Quick: pin to a previous version

Change the `@v1` ref to a specific tag:

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@v1.2.3
```

This is the safest and fastest rollback — no workflow logic changes, just a version pin.

### Full: revert to local workflows

1. Copy the workflow files from `formancehq/ci/.github/workflows/` into the repo's `.github/workflows/`.
2. Inline the reusable workflow calls — replace `uses: formancehq/ci/...` with the actual job steps from the called workflow.
3. Copy any composite actions the workflows reference (`actions/setup-nix`, etc.) into `.github/actions/`.
4. Verify the job names still produce `Dirty / Dirty` and `Tests / Test` check contexts, or remove the repo from `ruleset_ci_repositories` in `infra2/terraform/github/rulesets.tf`.
5. Open a PR, confirm checks pass, merge.

After the upstream issue is resolved, re-migrate using the [migration guide](migration.md).

## Emergency: unblock a repo when shared CI is broken

**Scenario**: A push to `formancehq/ci` breaks the `v1` floating tag and multiple repos are failing.

1. **Immediately**: pin affected repos to the last known-good `v1.x.y` tag (check `gh api repos/formancehq/ci/tags --jq '.[].name'` for available versions).
2. **Fix forward**: open a PR on `formancehq/ci` with the fix, get it reviewed and merged.
3. **Release**: tag a new point release (`v1.x.y`). The `major-tag.yml` workflow will stamp internal action refs and move `v1` automatically.
4. **Unpin**: repos can go back to `@v1` (Renovate PRs will do this automatically if the pin was in the workflow file).

### Who can re-tag

Only maintainers of `formancehq/ci` should force-push the floating `v1` tag. The tag update is a deployment-level action — treat it like a release.

## Deprecating a workflow or input

When removing or renaming a workflow input:

1. Add a deprecation notice to the workflow's doc page and the input's `description` field.
2. Keep the old input working for at least one minor version cycle (accepting both old and new names).
3. Remove the old input in the next major version.

When removing an entire workflow:

1. Mark it deprecated in the README and its doc page.
2. Keep it functional through the current major version's maintenance window.
3. Remove it in the next major.
