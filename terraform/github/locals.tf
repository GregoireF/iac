locals {
  # ---------------------------------------------------------------------------
  # Repositories
  # Add an entry here to create or manage a GitHub repo.
  # Set inject_standard_files = false for repos that manage their own .github/.
  # ---------------------------------------------------------------------------
  repositories = {
    iac = {
      description            = "Infrastructure as Code — experiments, modules and production-ready patterns."
      topics                 = ["opentofu", "iac", "devops", "platform-engineering", "github-actions", "ai"]
      visibility             = "public"
      has_issues             = true
      has_wiki               = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      archived               = false

      branch_protection = {
        enabled = true
        # Set to ["Plan"] after the first successful opentofu · github · plan run.
        required_status_checks       = []
        enforce_conventional_commits = true
        require_pr_reviews           = true
      }

      # This repo manages its own .github/ files directly — skip Terraform injection.
      inject_standard_files = false
    }

    utils = {
      description            = "Shared utilities and tooling."
      topics                 = ["typescript", "javascript", "python", "utils", "library"]
      visibility             = "public"
      has_issues             = true
      has_wiki               = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      archived               = false

      branch_protection = {
        enabled                = true
        required_status_checks = []
      }

      allow_auto_merge      = true
      inject_standard_files = true
    }

    # GitHub profile repository — README.md is injected via terraform/github/files.tf
    GregoireF = {
      description            = "GitHub profile."
      topics                 = []
      visibility             = "public"
      has_issues             = false
      has_wiki               = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      archived               = false

      branch_protection = {
        enabled                = false
        required_status_checks = []
      }

      inject_standard_files = false
    }
  }

  # ---------------------------------------------------------------------------
  # Standard labels applied to every managed repository.
  # Composite key format: "<repo>:<label>" for unique for_each addressing.
  # ---------------------------------------------------------------------------
  standard_labels = {
    # Type
    "bug" = {
      color       = "d73a4a"
      description = "Something isn't working"
    }
    "enhancement" = {
      color       = "a2eeef"
      description = "New feature or request"
    }
    "documentation" = {
      color       = "0075ca"
      description = "Improvements or additions to documentation"
    }
    "security" = {
      color       = "e11d48"
      description = "Security vulnerability or hardening"
    }
    "question" = {
      color       = "d876e3"
      description = "Further information is requested"
    }
    # Domain
    "terraform" = {
      color       = "7c3aed"
      description = "Related to OpenTofu / Terraform"
    }
    "github-actions" = {
      color       = "1d4ed8"
      description = "Related to GitHub Actions workflows"
    }
    "ai" = {
      color       = "059669"
      description = "Related to AI / GitHub Models integration"
    }
    # Status
    "needs-triage" = {
      color       = "fbbf24"
      description = "Awaiting triage"
    }
    "needs-info" = {
      color       = "fb923c"
      description = "More information needed from the author"
    }
    "in-progress" = {
      color       = "f97316"
      description = "Work in progress"
    }
    "blocked" = {
      color       = "dc2626"
      description = "Blocked by an external dependency"
    }
    # Priority
    "priority:high" = {
      color       = "991b1b"
      description = "High priority — address immediately"
    }
    "priority:medium" = {
      color       = "b45309"
      description = "Medium priority"
    }
    "priority:low" = {
      color       = "1e40af"
      description = "Low priority — nice to have"
    }
    # Domain — secrets management
    "secrets-management" = {
      color       = "7f1d1d"
      description = "Related to secrets management (Doppler, Vault)"
    }
    # Domain — dependencies
    "dependencies" = {
      color       = "0366d6"
      description = "Dependency updates (Dependabot)"
    }
  }

  # Flatten repos × labels into a single map for for_each.
  repo_labels = merge([
    for repo_name, _ in local.repositories : {
      for label_name, label_cfg in local.standard_labels :
        "${repo_name}:${label_name}" => merge(label_cfg, {
          repository = repo_name
          name       = label_name
        })
    }
  ]...)
}
