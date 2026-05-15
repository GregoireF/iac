# github/repository

Manages a GitHub repository with ruleset-based branch protection, deployment
environments, deploy keys, and optional injection of standard `.github/` files.

## Features

| Feature | Config key | Default |
|---|---|---|
| Repository settings (visibility, merge strategy, topics) | top-level | — |
| Ruleset branch protection (no force-push, no deletion) | `branch_protection.enabled` | `false` |
| Required status checks | `branch_protection.required_status_checks` | `[]` |
| Conventional commit enforcement | `branch_protection.enforce_conventional_commits` | `false` |
| PR required before merge (0 reviews — solo-dev friendly) | `branch_protection.require_pr_reviews` | `false` |
| Deployment environments with wait timers | `environments` | `{}` |
| Repository deploy keys | `deploy_keys` | `{}` |
| Inject CODEOWNERS + PR template | `inject_standard_files` | `false` |
| Dependabot auto-merge | `allow_auto_merge` | `false` |
| Vulnerability alerts | always `true` | — |

## Usage

```hcl
module "repository" {
  source   = "../../modules/github/repository"
  for_each = local.repositories

  owner  = var.github_owner
  name   = each.key
  config = each.value
}
```

Full configuration example — see [`terraform/github/locals.tf`](../../../terraform/github/locals.tf).

## Tests

Unit tests use `mock_provider` (no real API calls):

```bash
cd modules/github/repository
tofu init -backend=false && tofu test
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
