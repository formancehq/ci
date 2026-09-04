# Troubleshooting

## Check name mismatch

**Symptom:** Required checks show as "Waiting for status to be reported" and block merging.

**Cause:** GitHub constructs check contexts for reusable workflows as `CallerJobName / CalleeJobName`. The org ruleset expects `Dirty / Dirty` and `Tests / Test`. The GitHub UI adds the workflow name as a visual prefix (e.g. `Default / Dirty / Dirty (pull_request)`), but the actual check context used for matching does not include the workflow name or event type. If the caller job ID doesn't match (e.g. `DirtyCheck` instead of `Dirty`), the check context becomes `DirtyCheck / Dirty` and won't match.

**Fix:** Ensure the caller job ID matches the expected pattern — `Dirty` for dirty checks, `Tests` for test checks. Set `name: Default` for consistency across repos, but note this only affects the UI grouping, not the ruleset matching.

## Skipped job blocks merge

**Symptom:** PR stuck on "Expected — Waiting for status" for a required check.

**Cause:** Workflow-level `on.pull_request.paths` or branch filtering can prevent the workflow from running at all, which means the required check is never reported. (Note: a job-level `if:` that evaluates to false still reports a successful "skipped" status, so it won't block merging.)

**Fix:** Ensure the workflow always triggers on PRs. If some jobs should be conditional, use job-level `if:` conditions rather than workflow-level path filtering. If the repo genuinely can't produce both Dirty and Tests checks, remove it from `ruleset_ci_repositories`.

## Secret resolves to empty string

**Symptom:** A step silently fails — `git clone` with empty token, Codecov upload skipped, no error message.

**Cause:** The caller didn't pass a secret the callee expects. GitHub resolves missing secrets to `""` without erroring.

**Fix:** Check the workflow's `on.workflow_call.secrets` definition for required secrets and pass them explicitly:

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@v1
  secrets:
    GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```

## GITHUB_TOKEN: unbound variable

**Symptom:** Dirty job fails with `GITHUB_TOKEN: unbound variable` during pre-commit.

**Cause:** The repo's Justfile recipe references `$GITHUB_TOKEN` with `set -euo pipefail`. The variable isn't set in the reusable workflow environment.

**Fix:** Pass `NUMARY_GITHUB_TOKEN` as a secret to `go-dirty.yml`. The workflow exposes it as `GITHUB_TOKEN` in the pre-commit step's environment:

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@v1
  secrets:
    NUMARY_GITHUB_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
    GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```

## go env: command not found

**Symptom:** `setup-nix` action fails with `go env GOMODCACHE: command not found`.

**Cause:** The repo's Nix shell does not include Go (e.g. JS/TS only repos). The `setup-nix` action tries to extract Go environment variables by default.

**Fix:** Pass `skip-go: true`:

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@v1
  with:
    skip-go: true
```

## Cannot use steps alongside uses

**Symptom:** YAML error: "a job that uses `uses:` cannot also have `steps:`".

**Cause:** A reusable workflow job only supports `uses:`, `with:`, `secrets:`, `needs:`, `if:`, `permissions:`, `concurrency:`, and `strategy:`. No `steps:`, `runs-on:`, or `env:`.

**Fix:** Split into two jobs — one calling the reusable workflow, one with inline steps — and connect with `needs:`.

## Caller env/outputs not available in callee

**Symptom:** The called workflow can't see env vars or job outputs from the caller.

**Cause:** Caller and callee environments are fully isolated. Only `inputs` and `secrets` are passed through.

**Fix:** Pass needed values as explicit `with:` inputs. Use `outputs` on the callee to pass values back to the caller.

## Cannot mix secrets: inherit with explicit secrets

**Symptom:** YAML error when combining `secrets: inherit` with individual secret entries.

**Cause:** GitHub doesn't allow both forms on the same job.

**Fix:** Use one or the other. We use explicit secrets across all repos for clarity.

## Concurrency group evaluates to empty

**Symptom:** All workflow runs share one concurrency group, cancelling each other.

**Cause:** `concurrency.group` only supports `github`, `inputs`, `vars`, `needs`, `strategy`, `matrix` contexts — not `env`.

**Fix:** Use `inputs` or `github.*` properties for dynamic concurrency keys:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```
