# Cross-workspace outputs from the doppler stack.
# Requires global_remote_state = true on the doppler workspace.
# This is enabled automatically before each apply by the curl pre-step in
# .github/workflows/tofu-github-apply.yml — it cannot be managed by
# tfe_workspace_settings from within the same HCP Terraform run.
data "tfe_outputs" "doppler" {
  organization = "gregoiref"
  workspace    = "doppler"
}

# Sync Doppler CI service tokens to GitHub Actions secrets.
# The token is used by workflows to authenticate with Doppler and pull secrets.
# To add a repo: add its name to doppler_repos in terraform/github/locals.tf.
resource "github_actions_secret" "doppler_token" {
  for_each = local.doppler_repos

  repository      = each.key
  secret_name     = "DOPPLER_TOKEN"
  plaintext_value = data.tfe_outputs.doppler.values["ci_tokens"][each.key]
}
