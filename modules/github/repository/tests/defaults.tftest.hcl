# Unit tests for modules/github/repository.
# Uses mock_provider — no real GitHub API calls, no credentials required.
# Run with: tofu test

mock_provider "github" {}

# ---------------------------------------------------------------------------
# Shared input used by most test runs (override per run block as needed)
# ---------------------------------------------------------------------------
variables {
  owner = "test-owner"
  name  = "test-repo"

  config = {
    description            = "Test repository"
    topics                 = ["test", "mock"]
    visibility             = "public"
    has_issues             = true
    has_wiki               = false
    has_projects           = false
    allow_merge_commit     = false
    allow_squash_merge     = true
    allow_rebase_merge     = false
    delete_branch_on_merge = true
    archived               = false
    inject_standard_files  = false
    allow_auto_merge       = false

    branch_protection = {
      enabled                = true
      required_status_checks = ["Plan"]
    }

    environments = {}
    deploy_keys  = {}
  }
}

# ---------------------------------------------------------------------------
# Repository resource assertions
# ---------------------------------------------------------------------------

run "repository_name_matches_input" {
  command = plan

  assert {
    condition     = github_repository.this.name == var.name
    error_message = "repository name must match the input variable"
  }
}

run "vulnerability_alerts_always_enabled" {
  command = plan

  assert {
    condition     = github_repository.this.vulnerability_alerts == true
    error_message = "vulnerability_alerts must always be true — non-negotiable security baseline"
  }
}

run "merge_commits_disabled" {
  command = plan

  assert {
    condition     = github_repository.this.allow_merge_commit == false
    error_message = "allow_merge_commit must be false (squash-only policy)"
  }
}

run "delete_branch_on_merge_enabled" {
  command = plan

  assert {
    condition     = github_repository.this.delete_branch_on_merge == true
    error_message = "delete_branch_on_merge must be true to keep the repo clean"
  }
}

run "wiki_disabled_by_default" {
  command = plan

  assert {
    condition     = github_repository.this.has_wiki == false
    error_message = "has_wiki should be false (no wiki in the default config)"
  }
}

# ---------------------------------------------------------------------------
# Branch protection ruleset
# ---------------------------------------------------------------------------

run "branch_protection_creates_ruleset_when_enabled" {
  command = plan

  assert {
    condition     = length(github_repository_ruleset.default_branch) == 1
    error_message = "one ruleset must be created when branch_protection.enabled = true"
  }
}

run "branch_protection_disabled_creates_no_ruleset" {
  command = plan

  variables {
    config = {
      description            = "No protection"
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
      inject_standard_files  = false
      allow_auto_merge       = false

      branch_protection = {
        enabled                = false
        required_status_checks = []
      }

      environments = {}
      deploy_keys  = {}
    }
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch) == 0
    error_message = "no ruleset must be created when branch_protection.enabled = false"
  }
}

# ---------------------------------------------------------------------------
# Auto-merge
# ---------------------------------------------------------------------------

run "auto_merge_propagates_to_resource" {
  command = plan

  variables {
    config = {
      description            = "Auto-merge repo"
      topics                 = []
      visibility             = "public"
      has_issues             = true
      has_wiki               = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      archived               = false
      inject_standard_files  = false
      allow_auto_merge       = true

      branch_protection = {
        enabled                = true
        required_status_checks = []
      }

      environments = {}
      deploy_keys  = {}
    }
  }

  assert {
    condition     = github_repository.this.allow_auto_merge == true
    error_message = "allow_auto_merge must propagate from config to resource"
  }
}

# ---------------------------------------------------------------------------
# File injection
# ---------------------------------------------------------------------------

run "standard_files_injected_when_enabled" {
  command = plan

  variables {
    config = {
      description            = "Files injection repo"
      topics                 = []
      visibility             = "public"
      has_issues             = true
      has_wiki               = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      archived               = false
      inject_standard_files  = true
      allow_auto_merge       = false

      branch_protection = {
        enabled                = false
        required_status_checks = []
      }

      environments = {}
      deploy_keys  = {}
    }
  }

  assert {
    condition     = length(github_repository_file.codeowners) == 1
    error_message = "CODEOWNERS file must be created when inject_standard_files = true"
  }

  assert {
    condition     = length(github_repository_file.pr_template) == 1
    error_message = "PR template must be created when inject_standard_files = true"
  }
}

run "standard_files_not_injected_when_disabled" {
  command = plan

  assert {
    condition     = length(github_repository_file.codeowners) == 0
    error_message = "CODEOWNERS must not be created when inject_standard_files = false"
  }
}

# ---------------------------------------------------------------------------
# Conventional commits enforcement
# ---------------------------------------------------------------------------

run "conventional_commits_creates_ruleset" {
  command = plan

  variables {
    config = {
      description            = "Conventional commits repo"
      topics                 = []
      visibility             = "public"
      has_issues             = true
      has_wiki               = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      archived               = false
      inject_standard_files  = false
      allow_auto_merge       = false

      branch_protection = {
        enabled                      = true
        required_status_checks       = []
        enforce_conventional_commits = true
      }

      environments = {}
      deploy_keys  = {}
    }
  }

  assert {
    condition     = length(github_repository_ruleset.default_branch) == 1
    error_message = "ruleset must be created when enforce_conventional_commits = true"
  }
}

run "conventional_commits_off_by_default" {
  command = plan

  assert {
    condition     = length(github_repository_ruleset.default_branch) == 1
    error_message = "ruleset exists (branch_protection.enabled = true in default vars)"
  }
}
