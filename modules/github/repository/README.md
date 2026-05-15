# github/repository

Manages a GitHub repository with branch protection (ruleset-based), deployment
environments, deploy keys, and optional injection of standard `.github/` files.

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

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
