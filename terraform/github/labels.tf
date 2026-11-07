resource "github_issue_label" "standard" {
  for_each = local.repo_labels

  # each.value.repository is a plain string (repo name), not a reference to
  # module.repository — without this explicit depends_on, Terraform has no
  # graph edge between the two and may schedule label creation in parallel
  # with a brand-new repository's own creation. Observed in practice: 9 of
  # 17 labels for a freshly-created repo failed with
  # "POST .../labels: 404 Not Found" because the GitHub API hadn't finished
  # propagating the new repo yet. Existing repos never hit this (their
  # labels already exist, so it's a no-op diff), which is why it went
  # unnoticed until the next brand-new repository.
  depends_on = [module.repository]

  repository  = each.value.repository
  name        = each.value.name
  color       = each.value.color
  description = each.value.description
}

# ship-it's standard labels, on their way out of this configuration (GregoireF/ship-it#7).
# A removed block cannot target one for_each instance, so this takes two
# changes: this one moves the labels here, unchanged; the next one replaces
# this resource with a removed block and destroy = false, so OpenTofu forgets
# the labels without deleting them, and the issues keep theirs.
resource "github_issue_label" "handover" {
  for_each = local.standard_labels

  depends_on = [module.repository]

  repository  = "ship-it"
  name        = each.key
  color       = each.value.color
  description = each.value.description
}

moved {
  from = github_issue_label.standard["ship-it:bug"]
  to   = github_issue_label.handover["bug"]
}

moved {
  from = github_issue_label.standard["ship-it:enhancement"]
  to   = github_issue_label.handover["enhancement"]
}

moved {
  from = github_issue_label.standard["ship-it:documentation"]
  to   = github_issue_label.handover["documentation"]
}

moved {
  from = github_issue_label.standard["ship-it:security"]
  to   = github_issue_label.handover["security"]
}

moved {
  from = github_issue_label.standard["ship-it:question"]
  to   = github_issue_label.handover["question"]
}

moved {
  from = github_issue_label.standard["ship-it:terraform"]
  to   = github_issue_label.handover["terraform"]
}

moved {
  from = github_issue_label.standard["ship-it:github-actions"]
  to   = github_issue_label.handover["github-actions"]
}

moved {
  from = github_issue_label.standard["ship-it:ai"]
  to   = github_issue_label.handover["ai"]
}

moved {
  from = github_issue_label.standard["ship-it:needs-triage"]
  to   = github_issue_label.handover["needs-triage"]
}

moved {
  from = github_issue_label.standard["ship-it:needs-info"]
  to   = github_issue_label.handover["needs-info"]
}

moved {
  from = github_issue_label.standard["ship-it:in-progress"]
  to   = github_issue_label.handover["in-progress"]
}

moved {
  from = github_issue_label.standard["ship-it:blocked"]
  to   = github_issue_label.handover["blocked"]
}

moved {
  from = github_issue_label.standard["ship-it:priority:high"]
  to   = github_issue_label.handover["priority:high"]
}

moved {
  from = github_issue_label.standard["ship-it:priority:medium"]
  to   = github_issue_label.handover["priority:medium"]
}

moved {
  from = github_issue_label.standard["ship-it:priority:low"]
  to   = github_issue_label.handover["priority:low"]
}

moved {
  from = github_issue_label.standard["ship-it:secrets-management"]
  to   = github_issue_label.handover["secrets-management"]
}

moved {
  from = github_issue_label.standard["ship-it:dependencies"]
  to   = github_issue_label.handover["dependencies"]
}
