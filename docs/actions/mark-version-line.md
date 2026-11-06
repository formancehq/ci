# mark-version-line

Tags the branch point of a release branch with the marker of the next version line
(RFC-0013, "Marking version lines"). Usually run through the
[`mark-version-line.yml`](../../.github/workflows/mark-version-line.yml) reusable workflow.

| Branch | Marker on the branch point |
|--------|----------------------------|
| `release/vX.Y` | `vX.(Y+1).0-0` |
| `release/vX` | `v(X+1).0.0-0` |

The branch point is the merge base of the release branch and the default branch. Nothing is
tagged when the branch name matches neither form, when a tag of the marker's line
(`vX.(Y+1).*`) already exists, or when the two branches share no history.

Markers are what moves the default branch to the next line: once `release/v2.4` is cut,
`main` builds become `v2.5.0-0.dev.N.g…` instead of `v2.4.x-dev.N.g…`.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `branch` | the triggering ref | Release branch |
| `default-branch` | the repository's default branch | Branch the release was cut from |
| `dry-run` | `'false'` | Compute the marker without tagging or pushing |

## Outputs

| Name | Description |
|------|-------------|
| `marker` | Tag created (empty when nothing was tagged) |
| `branch-point` | Commit the marker points to |
| `pushed` | `true` when a tag was pushed |

## Caller

```yaml
name: Mark Version Line
on:
  create:
  workflow_dispatch:
    inputs:
      branch:
        description: Release branch to mark (release/vX.Y or release/vX)
        required: true
      dry-run:
        type: boolean
        default: true

jobs:
  Mark:
    if: github.event_name == 'workflow_dispatch' || (github.ref_type == 'branch' && startsWith(github.ref_name, 'release/'))
    uses: formancehq/ci/.github/workflows/mark-version-line.yml@v1
    permissions:
      contents: write
    with:
      branch: ${{ inputs.branch || github.ref_name }}
      dry-run: ${{ inputs.dry-run || false }}
```

`workflow_dispatch` backfills markers for release branches cut before the workflow existed.

## Requirements

- The release workflow must ignore markers before any marker is pushed:

  ```yaml
  on:
    push:
      tags:
        - 'v*.*.*'
        - '!v*.*.*-0'
  ```

  Markers pushed by this workflow use `GITHUB_TOKEN` and do not trigger other workflows,
  but markers pushed by hand do.
- Tag rulesets must allow `github-actions[bot]` to create `v*.*.*-0` tags.
- New majors started outside a `release/vX` cut need their `vX.0.0-0` marker pushed by hand.
