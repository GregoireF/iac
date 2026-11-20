# GregoireF/homebrew-tap — the distribution hub (GregoireF/homebrew-tap,
# docs/adr/0003-signed-commits-as-the-owner.md).
#
# The tap's sync workflow commits as the owner, signed with an SSH key used
# by CI only, and pushes to main with its own GITHUB_TOKEN. This file holds:
#   - the ruleset of main: signed commits, no force push, no deletion, for
#     everyone (no bypass: the owner signs every commit too);
#   - the private half of the CI signing key, secret TAP_SIGNING_KEY of the
#     `publish` environment (declared in locals.tf), read only by that job.
#
# Its public half must be a *signing* key of the account so that GitHub shows
# the commits as Verified. The provider (6.12) has no resource for SSH signing
# keys, so that one step is done with the GitHub CLI.
#
# Generate once, then delete the files:
#   ssh-keygen -t ed25519 -N "" -C "homebrew-tap CI signing" -f tap_signing
#   gh ssh-key add tap_signing.pub --type signing --title "homebrew-tap CI signing"
#   HCP Terraform workspace variable tap_signing_private_key (sensitive) = tap_signing
# Rotate yearly: new pair, same steps, then delete the old signing key
# (gh ssh-key list; gh ssh-key delete <id>).

variable "tap_signing_private_key" {
  type        = string
  description = "Private half of the homebrew-tap CI signing key (OpenSSH format)."
  sensitive   = true
  default     = ""
}

resource "github_repository_ruleset" "homebrew_tap_main" {
  name        = "main-integrity"
  repository  = module.repository["homebrew-tap"].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion            = true
    non_fast_forward    = true
    required_signatures = true
  }

  # No bypass_actors: the rules apply to the owner, to the sync workflow and
  # to Dependabot's merges alike (GitHub signs squash merges).

  depends_on = [module.repository]
}

resource "github_actions_environment_secret" "homebrew_tap_signing_key" {
  count = var.tap_signing_private_key != "" ? 1 : 0

  repository      = module.repository["homebrew-tap"].name
  environment     = "publish"
  secret_name     = "TAP_SIGNING_KEY"
  plaintext_value = var.tap_signing_private_key

  depends_on = [module.repository]
}
