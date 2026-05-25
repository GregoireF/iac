locals {
  # ---------------------------------------------------------------------------
  # Repositories
  # Add an entry here to create or manage a GitHub repo.
  # Set inject_standard_files = false for repos that manage their own .github/.
  # ---------------------------------------------------------------------------
  repositories = {
    ".github" = {
      description            = "Default community health files and reusable GitHub templates for all repositories."
      topics                 = ["github-templates", "issue-templates", "pull-request-templates", "community-health", "github-actions"]
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
        required_status_checks = ["Commitlint"]
        require_pr_reviews     = false
      }

      # Source of templates for all repos — manages its own .github/ files.
      inject_standard_files = false
    }

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
        # "Commitlint" runs on every PR regardless of changed paths — safe to require.
        # Path-conditional checks (plan, trivy…) are not listed to avoid blocking PRs
        # where those workflows are not triggered.
        # commit_message_pattern ruleset rule is unsupported on personal repos;
        # conventional commits are enforced via the commitlint CI workflow instead.
        required_status_checks       = ["Commitlint"]
        enforce_conventional_commits = false
        require_pr_reviews           = true
        dismiss_stale_reviews        = true
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
        required_status_checks = ["Commitlint"]
      }

      allow_auto_merge      = true
      inject_standard_files = true
    }

    homebrew-tap = {
      description            = "Homebrew formulae for GregoireF tools."
      topics                 = ["homebrew", "homebrew-tap", "cli", "devtools"]
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

    addlicense = {
      description            = "Fast, minimal license header manager for monorepos and CI pipelines."
      topics                 = ["go", "cli", "license", "spdx", "reuse", "compliance", "oss-tooling", "devtools", "ci"]
      visibility             = "public"
      has_issues             = true
      has_wiki               = true
      has_discussions        = true
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      allow_auto_merge       = true
      delete_branch_on_merge = true
      archived               = false

      branch_protection = {
        enabled                = true
        required_status_checks = ["Commitlint"]
        require_pr_reviews     = false
      }

      inject_standard_files = false
    }

    addlicense-action = {
      description            = "GitHub Action — add, check and remove license headers using addlicense."
      topics                 = ["github-action", "license", "spdx", "reuse", "compliance", "ci", "devtools"]
      visibility             = "public"
      has_issues             = true
      has_wiki               = false
      has_discussions        = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      allow_auto_merge       = true
      delete_branch_on_merge = true
      archived               = false

      branch_protection = {
        enabled                = true
        required_status_checks = ["Commitlint"]
        require_pr_reviews     = false
        # Allow github-actions[bot] to push version-bump commits after tag-release.yml.
        bypass_actors = [
          { actor_id = 15368, actor_type = "Integration", bypass_mode = "always" }
        ]
      }

      inject_standard_files = false
    }

    addlicense-npm = {
      description            = "npm package — @gregoiref/addlicense CLI for Node.js projects and CI."
      topics                 = ["npm", "nodejs", "cli", "license", "spdx", "reuse", "compliance", "devtools", "typescript"]
      visibility             = "public"
      has_issues             = true
      has_wiki               = false
      has_discussions        = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      allow_auto_merge       = true
      delete_branch_on_merge = true
      archived               = false

      branch_protection = {
        enabled                = true
        required_status_checks = ["Commitlint"]
        require_pr_reviews     = false
        # Allow github-actions[bot] to push version-bump commits after publish.yml.
        bypass_actors = [
          { actor_id = 15368, actor_type = "Integration", bypass_mode = "always" }
        ]
      }

      inject_standard_files = false
    }

    addlicense-winget = {
      description            = "WinGet manifests for addlicense — Windows Package Manager."
      topics                 = ["winget", "windows", "package-manager", "license", "spdx", "cli", "devtools"]
      visibility             = "public"
      has_issues             = true
      has_wiki               = false
      has_discussions        = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      allow_auto_merge       = false
      delete_branch_on_merge = true
      archived               = false

      branch_protection = {
        enabled                = false
        required_status_checks = []
      }

      inject_standard_files = false
    }

    notiftk = {
      description            = "TikTok live status API — REST, SSE et webhooks."
      topics                 = ["python", "fastapi", "tiktok", "api", "sse", "webhooks", "self-hosted"]
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
        required_status_checks = ["Commitlint"]
        require_pr_reviews     = false
        dismiss_stale_reviews  = false
      }

      # Manages its own .github/ workflows — skip Terraform injection.
      inject_standard_files = false
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

  # ---------------------------------------------------------------------------
  # Repos with a Doppler project + ci config — get a DOPPLER_TOKEN Actions secret.
  # Must be a subset of local.repositories keys.
  # ---------------------------------------------------------------------------
  doppler_repos = toset(["iac", "utils"])

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
