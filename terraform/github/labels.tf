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

# ship-it's standard labels, handed over to ship-it (GregoireF/ship-it#7),
# which applies its own taxonomy with `ship sync`. OpenTofu forgets them
# without deleting them, so the issues keep their labels. The previous change
# moved them to this address, because a removed block cannot target one
# for_each instance.
removed {
  from = github_issue_label.handover

  lifecycle {
    destroy = false
  }
}
