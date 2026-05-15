variable "github_owner" {
  type        = string
  description = "GitHub username or organization name."
}

variable "github_app_id" {
  type        = string
  description = "GitHub App ID. Store as a sensitive workspace variable in HCP Terraform."
  sensitive   = true
}

variable "github_app_installation_id" {
  type        = string
  description = "GitHub App installation ID. Store as a sensitive workspace variable in HCP Terraform."
  sensitive   = true
}

variable "github_app_pem_file" {
  type        = string
  description = "GitHub App private key (full PEM content). Store as a sensitive workspace variable in HCP Terraform."
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Optional: SSH & GPG keys for the account.
# Add these as HCP Terraform workspace variables when needed.
# SSH public keys are not sensitive; GPG armored keys are also public.
# ---------------------------------------------------------------------------

variable "ssh_public_keys" {
  type        = map(string)
  description = "Map of SSH public keys to register on the account (label → public key). Optional — defaults to empty."
  default     = {}
}

variable "gpg_public_keys" {
  type        = map(string)
  description = "Map of GPG armored public keys to register on the account (label → armored key). Optional — defaults to empty."
  default     = {}
}
