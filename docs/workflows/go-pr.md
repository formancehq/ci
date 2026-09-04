# go-pr.yml

Validates PR titles against the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Usage

```yaml
PR:
  if: github.event_name == 'pull_request'
  uses: formancehq/ci/.github/workflows/go-pr.yml@v1
  permissions:
    pull-requests: read
    statuses: write
```

No inputs or secrets required.
