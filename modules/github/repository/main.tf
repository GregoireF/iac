resource "github_repository" "this" {
  name        = var.name
  description = var.config.description
  visibility  = var.config.visibility

  has_issues   = var.config.has_issues
  has_wiki     = var.config.has_wiki
  has_projects = var.config.has_projects

  allow_merge_commit     = var.config.allow_merge_commit
  allow_squash_merge     = var.config.allow_squash_merge
  allow_rebase_merge     = var.config.allow_rebase_merge
  delete_branch_on_merge = var.config.delete_branch_on_merge
  allow_auto_merge       = var.config.allow_auto_merge

  topics = var.config.topics

  archived             = var.config.archived
  vulnerability_alerts = true

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [auto_init]
  }
}

# Ruleset-based branch protection.
# Protects the default branch against deletion, force-pushes, and optionally
# enforces required status checks. Admins can bypass to prevent self-locking.
resource "github_repository_ruleset" "default_branch" {
  count = var.config.branch_protection.enabled ? 1 : 0

  name        = "protect-default-branch"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    dynamic "required_status_checks" {
      for_each = length(var.config.branch_protection.required_status_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = true

        dynamic "required_check" {
          for_each = var.config.branch_protection.required_status_checks
          content {
            context        = required_check.value
            integration_id = 0
          }
        }
      }
    }

    dynamic "commit_message_pattern" {
      for_each = var.config.branch_protection.enforce_conventional_commits ? [1] : []
      content {
        name     = "conventional-commits"
        negate   = false
        operator = "regex"
        pattern  = "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\\(.+\\))?(!)?: .{1,100}$"
      }
    }
  }

  bypass_actors {
    actor_id    = 5 # Admin repository role
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }
}

# Deployment environments with optional wait timers and branch policies.
# Used for staging/production gates and environment-scoped secrets/variables.
resource "github_repository_environment" "this" {
  for_each = var.config.environments

  repository  = github_repository.this.name
  environment = each.key
  wait_timer  = each.value.wait_timer_minutes

  deployment_branch_policy {
    protected_branches     = each.value.deployment_branch_policy == "protected"
    custom_branch_policies = false
  }

  depends_on = [github_repository.this]
}

# Environment-scoped variables (non-sensitive).
locals {
  env_variables = merge([
    for env_name, env_cfg in var.config.environments : {
      for var_name, var_value in env_cfg.variables :
        "${env_name}:${var_name}" => {
          environment   = env_name
          variable_name = var_name
          value         = var_value
        }
    }
  ]...)
}

resource "github_actions_environment_variable" "this" {
  for_each = local.env_variables

  repository    = github_repository.this.name
  environment   = each.value.environment
  variable_name = each.value.variable_name
  value         = each.value.value

  depends_on = [github_repository_environment.this]
}

# Repository deploy keys — SSH public keys for read (or write) CI access.
resource "github_repository_deploy_key" "this" {
  for_each = var.config.deploy_keys

  repository = github_repository.this.name
  title      = each.key
  key        = each.value.public_key
  read_only  = each.value.read_only
}

# Standard .github/ files injected into repos that don't manage their own.
resource "github_repository_file" "codeowners" {
  count = var.config.inject_standard_files ? 1 : 0

  repository          = github_repository.this.name
  branch              = "main"
  file                = ".github/CODEOWNERS"
  content             = "* @${var.owner}\n"
  commit_message      = "chore: add CODEOWNERS [skip ci]"
  overwrite_on_create = true

  lifecycle {
    ignore_changes = [commit_sha]
  }
}

resource "github_repository_file" "pr_template" {
  count = var.config.inject_standard_files ? 1 : 0

  repository          = github_repository.this.name
  branch              = "main"
  file                = ".github/pull_request_template.md"
  content             = file("${path.module}/templates/pull_request_template.md")
  commit_message      = "chore: add PR template [skip ci]"
  overwrite_on_create = true

  lifecycle {
    ignore_changes = [commit_sha]
  }
}
