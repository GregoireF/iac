# GregoireF/telly — live French TV and radio for Windows.
#
# The nightly `channels` workflow tests the channel list, signs it (ECDSA P-256 / SHA-256) and
# publishes it; installed copies of Telly only accept a list whose signature matches the public
# key built into the app. This file holds:
#   - DOPPLER_TOKEN, a secret of the `channels` environment only (not repository-wide, unlike
#     local.doppler_repos): the signing job reads the private key CHANNELS_SIGNING_KEY from
#     Doppler telly/ci with it, and no other job or branch can;
#   - CODE_SCANNING=true: the repository is public, so CodeQL, zizmor's SARIF upload, dependency
#     review and Scorecard can run (their jobs are skipped while the variable is unset).
#
# Rotate the key: new key pair, new public key in Telly's Config.cs and a release, then
# `doppler secrets set CHANNELS_SIGNING_KEY --project telly --config ci`.

resource "github_actions_environment_secret" "telly_doppler_token" {
  repository      = module.repository["telly"].name
  environment     = "channels"
  secret_name     = "DOPPLER_TOKEN"
  plaintext_value = data.tfe_outputs.doppler.values["ci_tokens"]["telly"]

  depends_on = [module.repository]
}

resource "github_actions_variable" "telly_code_scanning" {
  repository    = module.repository["telly"].name
  variable_name = "CODE_SCANNING"
  value         = "true"

  depends_on = [module.repository]
}
