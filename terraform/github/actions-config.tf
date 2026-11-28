# Repository-level Actions variables managed by Terraform.
# Non-sensitive configuration surfaced to workflows without hard-coding values.

locals {
  # Repos that expose GITHUB_OWNER to their workflows (e.g. integration tests).
  actions_var_repos = toset(["iac"])
}

resource "github_actions_variable" "github_owner" {
  for_each = local.actions_var_repos

  repository    = module.repository[each.key].name
  variable_name = "GH_OWNER"
  value         = var.github_owner

  depends_on = [module.repository]
}

# kiwa's scorecard.yml publishes its results to scorecard.dev only when this
# is true; unset, the OpenSSF Scorecard badge reads "invalid repo path".
resource "github_actions_variable" "kiwa_scorecard_publish" {
  repository    = module.repository["kiwa"].name
  variable_name = "SCORECARD_PUBLISH"
  value         = "true"

  depends_on = [module.repository]
}
