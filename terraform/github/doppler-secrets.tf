data "tfe_outputs" "doppler" {
  organization = "gregoiref"
  workspace    = "doppler"
}

resource "github_actions_secret" "doppler_token" {
  # Static set avoids iterating over a sensitive value directly.
  for_each = toset(["iac", "utils"])

  repository      = each.key
  secret_name     = "DOPPLER_TOKEN"
  plaintext_value = nonsensitive(data.tfe_outputs.doppler.values["ci_tokens"])[each.key]
}
