data "tfe_outputs" "doppler" {
  organization = "gregoiref"
  workspace    = "doppler"
}

resource "github_actions_secret" "doppler_token" {
  for_each = toset(["iac", "utils"])

  repository      = each.key
  secret_name     = "DOPPLER_TOKEN"
  plaintext_value = data.tfe_outputs.doppler.values["ci_tokens"][each.key]
}
