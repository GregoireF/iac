# Actions secrets for the addlicense ecosystem.
#
# Required HCP Terraform workspace variables (sensitive = true):
#   - addlicense_dispatch_token  : GitHub PAT, public_repo scope on
#                                  addlicense-action / addlicense-npm / addlicense-winget.
#                                  Used by addlicense release.yml to fire repository_dispatch.
#   - npm_token                  : npm automation token for @gregoiref scope.
#                                  Used by addlicense-npm publish.yml.
#   - winget_submit_token        : GitHub PAT, public_repo scope on microsoft/winget-pkgs.
#                                  Used by addlicense-winget submit.yml.

variable "addlicense_dispatch_token" {
  type        = string
  description = "GitHub PAT (public_repo) used by addlicense to dispatch releases to ecosystem repos."
  sensitive   = true
  default     = ""
}

variable "npm_token" {
  type        = string
  description = "npm automation token for publishing @gregoiref/* packages."
  sensitive   = true
  default     = ""
}

variable "winget_submit_token" {
  type        = string
  description = "GitHub PAT (public_repo on microsoft/winget-pkgs) for wingetcreate submissions."
  sensitive   = true
  default     = ""
}

# ── addlicense — DISPATCH_TOKEN ───────────────────────────────────────────────

resource "github_actions_secret" "addlicense_dispatch_token" {
  count = var.addlicense_dispatch_token != "" ? 1 : 0

  repository      = module.repository["addlicense"].name
  secret_name     = "DISPATCH_TOKEN"
  plaintext_value = var.addlicense_dispatch_token

  depends_on = [module.repository]
}

# ── addlicense-npm — NPM_TOKEN ────────────────────────────────────────────────

resource "github_actions_secret" "npm_token" {
  count = var.npm_token != "" ? 1 : 0

  repository      = module.repository["addlicense-npm"].name
  secret_name     = "NPM_TOKEN"
  plaintext_value = var.npm_token

  depends_on = [module.repository]
}

# ── addlicense-winget — WINGET_SUBMIT_TOKEN ───────────────────────────────────

resource "github_actions_secret" "winget_submit_token" {
  count = var.winget_submit_token != "" ? 1 : 0

  repository      = module.repository["addlicense-winget"].name
  secret_name     = "WINGET_SUBMIT_TOKEN"
  plaintext_value = var.winget_submit_token

  depends_on = [module.repository]
}
