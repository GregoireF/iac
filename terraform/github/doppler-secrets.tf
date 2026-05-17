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
# Extend the for_each set when a new repo gets a Doppler project + ci config.
resource "github_actions_secret" "doppler_token" {
  for_each = toset(["iac", "utils"])

  repository      = each.key
  secret_name     = "DOPPLER_TOKEN"
  plaintext_value = data.tfe_outputs.doppler.values["ci_tokens"][each.key]
}
