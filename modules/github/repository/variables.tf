variable "owner" {
  type        = string
  description = "GitHub username or organization name."
}

variable "name" {
  type        = string
  description = "Repository name (must be unique within the owner's account)."

  validation {
    condition     = length(var.name) > 0 && can(regex("^[a-zA-Z0-9._-]+$", var.name))
    error_message = "Repository name must be non-empty and contain only letters, digits, dots, underscores, or hyphens."
  }
}

variable "config" {
  description = "Repository configuration."

  type = object({
    description            = string
    topics                 = list(string)
    visibility             = string
    has_issues             = bool
    has_wiki               = bool
    has_projects           = bool
    allow_merge_commit     = bool
    allow_squash_merge     = bool
    allow_rebase_merge     = bool
    delete_branch_on_merge = bool
    archived               = bool
    inject_standard_files  = bool

    # Enable auto-merge on this repository.
    # Individual PRs still need to opt-in via `gh pr merge --auto`.
    allow_auto_merge = optional(bool, false)

    branch_protection = object({
      enabled                      = bool
      required_status_checks       = list(string)
      enforce_conventional_commits = optional(bool, false)
    })

    # GitHub Environments for deployment gates.
    # Useful for staging/production promotion with wait timers.
    environments = optional(map(object({
      wait_timer_minutes       = optional(number, 0)
      deployment_branch_policy = optional(string, "protected") # protected | all
      variables                = optional(map(string), {})
    })), {})

    # Repository-level deploy keys (SSH public keys for CI read access).
    deploy_keys = optional(map(object({
      public_key = string
      read_only  = optional(bool, true)
    })), {})
  })

  validation {
    condition     = contains(["public", "private", "internal"], var.config.visibility)
    error_message = "visibility must be one of: public, private, internal."
  }

  validation {
    condition = alltrue([
      for env in values(var.config.environments) :
      contains(["protected", "all"], env.deployment_branch_policy)
    ])
    error_message = "deployment_branch_policy must be 'protected' or 'all'."
  }
}
