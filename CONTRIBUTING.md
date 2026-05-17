# Contributing

## Prerequisites

| Tool | Install |
|------|---------|
| [tenv](https://github.com/tofuutils/tenv) | `brew install tenv` / [releases](https://github.com/tofuutils/tenv/releases) |
| [pre-commit](https://pre-commit.com) | `pip install pre-commit` |
| [Node.js](https://nodejs.org) ≥ 18 | for commitlint |

```bash
# Install the OpenTofu version declared in .opentofu-version
tenv tofu install

# Install git hooks (commitlint, tflint, trivy, checkov…)
pre-commit install --hook-type commit-msg --hook-type pre-commit
```

## Commit format

This repo enforces [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>
```

Common types: `feat`, `fix`, `chore`, `docs`, `refactor`, `ci`, `test`.

Examples:
```
feat(github): add addlicense repository
fix(doppler): use nonsensitive() per-value in ci_tokens output
chore(deps): bump checkov to 3.2.530
```

## Workflow

1. Branch from `main` — `feat/<topic>` or `fix/<topic>`
2. Write code; hooks run on every commit
3. Open a PR — Commitlint, Trivy, Checkov, and OpenTofu plan run automatically
4. Squash-merge after one approval

## Stack layout

```
terraform/
  github/   — GitHub repos, branch protection, secrets (HCP workspace: github)
  doppler/  — Doppler projects and CI service tokens  (HCP workspace: doppler)
modules/
  github/repository/  — reusable module called by terraform/github
```

## HCP Terraform

Applies run remotely on [app.terraform.io](https://app.terraform.io) under the `gregoiref` organisation. Workspace variables (tokens, secrets) must be set there — never committed to git.

Required workspace variables:

| Workspace | Variable | Description |
|-----------|----------|-------------|
| `github`  | `GITHUB_TOKEN` | PAT with repo + admin scopes |
| `doppler` | `DOPPLER_TOKEN` | Doppler service token |
| `github`  | `TF_API_TOKEN` | HCP Terraform API token (for curl pre-step) |

Required GitHub repository variables:

| Variable | Description |
|----------|-------------|
| `TF_DOPPLER_WORKSPACE_ID` | HCP Terraform workspace ID for the doppler workspace |

## Skipping hooks

Pre-commit hooks can be bypassed with `SKIP=<hook-id> git commit …` for a specific hook, or `git commit --no-verify` to skip all (use sparingly — CI enforces the same checks).
