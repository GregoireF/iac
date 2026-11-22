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
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.13 |
| <a name="requirement_github"></a> [github](#requirement_github) | >= 6.13 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_github"></a> [github](#provider_github) | >= 6.13 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [github_actions_environment_variable.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_repository.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_deploy_key.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_deploy_key) | resource |
| [github_repository_environment.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [github_repository_file.codeowners](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file) | resource |
| [github_repository_file.pr_template](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file) | resource |
| [github_repository_ruleset.additional](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_ruleset.default_branch](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_vulnerability_alerts.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_vulnerability_alerts) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input_config) | Repository configuration. | <pre>object({<br/>    description            = string<br/>    topics                 = list(string)<br/>    visibility             = string<br/>    has_issues             = bool<br/>    has_wiki               = bool<br/>    has_projects           = bool<br/>    has_discussions        = optional(bool, false)<br/>    allow_merge_commit     = bool<br/>    allow_squash_merge     = bool<br/>    allow_rebase_merge     = bool<br/>    delete_branch_on_merge = bool<br/>    archived               = bool<br/>    inject_standard_files  = bool<br/><br/>    # Enable auto-merge on this repository.<br/>    # Individual PRs still need to opt-in via `gh pr merge --auto`.<br/>    allow_auto_merge = optional(bool, false)<br/><br/>    branch_protection = object({<br/>      enabled                = bool<br/>      required_status_checks = list(string)<br/>      # Require a pull request's branch to be up to date with the default<br/>      # branch before it merges. false lets a green pull request merge at once<br/>      # (auto-merge), the CI on the default branch catching what two pull<br/>      # requests break together.<br/>      strict_status_checks         = optional(bool, true)<br/>      enforce_conventional_commits = optional(bool, false)<br/>      # Require changes to go through a PR (0 reviews required — solo-developer friendly).<br/>      require_pr_reviews = optional(bool, false)<br/>      # Let the Admin role bypass the default branch's ruleset (the default, to<br/>      # prevent self-locking). false applies the rules to administrators too.<br/>      admin_bypass = optional(bool, true)<br/>      # Dismiss existing approvals when new commits are pushed to the PR branch.<br/>      # Improves OSSF BranchProtectionID score. No-op when require_pr_reviews = false.<br/>      dismiss_stale_reviews = optional(bool, false)<br/>      # Additional bypass actors beyond the default Admin role bypass.<br/>      # Each entry maps to a github_repository_ruleset bypass_actors block.<br/>      # Common: { actor_id = 15368, actor_type = "Integration", bypass_mode = "always" }<br/>      # for github-actions[bot] (needed when the bot must push version-bump commits to main).<br/>      bypass_actors = optional(list(object({<br/>        actor_id    = number<br/>        actor_type  = string<br/>        bypass_mode = string<br/>      })), [])<br/>    })<br/><br/>    # Additional named rulesets targeting specific branches (e.g., develop).<br/>    # Key = ruleset name, value = ruleset config.<br/>    additional_rulesets = optional(map(object({<br/>      branch_pattern         = string<br/>      required_status_checks = optional(list(string), [])<br/>      require_pr_reviews     = optional(bool, false)<br/>      # Let the Admin role bypass this ruleset, as by default for the default<br/>      # branch's (admin_bypass above).<br/>      admin_bypass = optional(bool, true)<br/>      bypass_actors = optional(list(object({<br/>        actor_id    = number<br/>        actor_type  = string<br/>        bypass_mode = string<br/>      })), [])<br/>    })), {})<br/><br/>    # GitHub Environments for deployment gates.<br/>    # Useful for staging/production promotion with wait timers.<br/>    environments = optional(map(object({<br/>      wait_timer_minutes       = optional(number, 0)<br/>      deployment_branch_policy = optional(string, "protected") # protected | all<br/>      variables                = optional(map(string), {})<br/>    })), {})<br/><br/>    # Repository-level deploy keys (SSH public keys for CI read access).<br/>    deploy_keys = optional(map(object({<br/>      public_key = string<br/>      read_only  = optional(bool, true)<br/>    })), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input_name) | Repository name (must be unique within the owner's account). | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input_owner) | GitHub username or organization name. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_html_url"></a> [html_url](#output_html_url) | Repository URL. |
| <a name="output_http_clone_url"></a> [http_clone_url](#output_http_clone_url) | HTTPS clone URL. |
| <a name="output_name"></a> [name](#output_name) | Repository name. |
| <a name="output_node_id"></a> [node_id](#output_node_id) | GraphQL node ID. |
| <a name="output_ssh_clone_url"></a> [ssh_clone_url](#output_ssh_clone_url) | SSH clone URL. |
<!-- END_TF_DOCS -->
