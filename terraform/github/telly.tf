# GregoireF/telly — live French TV and radio for Windows.
#
# The nightly `channels` workflow tests the channel list, signs it (ECDSA P-256 / SHA-256) and
# publishes it on the `channels` branch; installed copies of Telly only accept a list whose
# signature matches the public key built into the app. This file holds:
#   - the private half of that key, secret CHANNELS_SIGNING_KEY of the `channels` environment
#     (declared in locals.tf), read only by the signing job;
#   - CODE_SCANNING=true: the repository is public, so CodeQL, zizmor's SARIF upload, dependency
#     review and Scorecard can run (their jobs are skipped while the variable is unset).
#
# HCP Terraform workspace variable telly_channels_signing_key (sensitive) = the PEM file
# %USERPROFILE%\.telly\channels-signing-key.pem.
# Rotate: new key pair, new public key in Telly's Config.cs and a release, then this variable.

variable "telly_channels_signing_key" {
  type        = string
  description = "Private key (PEM) that signs Telly's channel list."
  sensitive   = true
  default     = ""
}

resource "github_actions_environment_secret" "telly_channels_signing_key" {
  count = var.telly_channels_signing_key != "" ? 1 : 0

  repository      = module.repository["telly"].name
  environment     = "channels"
  secret_name     = "CHANNELS_SIGNING_KEY"
  plaintext_value = var.telly_channels_signing_key

  depends_on = [module.repository]
}

resource "github_actions_variable" "telly_code_scanning" {
  repository    = module.repository["telly"].name
  variable_name = "CODE_SCANNING"
  value         = "true"

  depends_on = [module.repository]
}
