# Troubleshooting

## Check name mismatch

**Symptom:** Required checks show as "Waiting for status to be reported" and block merging.

**Cause:** GitHub constructs check names as `WorkflowName / CallerJobName / CalleeJobName`. If the workflow is named `Main` instead of `Default`, checks appear as `Main / Dirty / Dirty` but the ruleset expects `Default / Dirty / Dirty`.

**Fix:** Set `name: Default` on line 1 of the workflow file. All repos must use the same workflow name for the org ruleset to work.

## Skipped job blocks merge

**Symptom:** PR stuck on "Expected — Waiting for status" for a check that was skipped via `if:`.

**Cause:** Skipped jobs don't report a status check at all. If the check is in `ruleset_ci_repositories`, the ruleset waits forever.

**Fix:** Either remove the `if:` condition so the job always runs, or remove the repo from `ruleset_ci_repositories` if it doesn't always produce both Dirty and Tests checks.

## Secret resolves to empty string

**Symptom:** A step silently fails — `git clone` with empty token, Codecov upload skipped, no error message.

**Cause:** The caller didn't pass a secret the callee expects. GitHub resolves missing secrets to `""` without erroring.

**Fix:** Check the workflow's `on.workflow_call.secrets` definition for required secrets and pass them explicitly:

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@main
  secrets:
    GIT_PRIVATE_TOKEN: ${{ secrets.NUMARY_GITHUB_TOKEN }}
```

## GITHUB_TOKEN: unbound variable

**Symptom:** Dirty job fails with `GITHUB_TOKEN: unbound variable` during pre-commit.

**Cause:** The repo's Justfile recipe references `$GITHUB_TOKEN` with `set -euo pipefail`. The variable isn't set in the reusable workflow environment.

**Fix:** Pass `NUMARY_GITHUB_TOKEN` as a secret to `go-dirty.yml`. The workflow exposes it as `GITHUB_TOKEN` in the pre-commit step's environment:

```yaml
Dirty:
  uses: formancehq/ci/.github/workflows/go-dirty.yml@main
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
  uses: formancehq/ci/.github/workflows/go-dirty.yml@main
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
