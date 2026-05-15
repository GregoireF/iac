resource "github_issue_label" "standard" {
  for_each = local.repo_labels

  repository  = each.value.repository
  name        = each.value.name
  color       = each.value.color
  description = each.value.description
}
