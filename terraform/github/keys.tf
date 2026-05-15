# Account-level SSH keys — used for git operations and deploy access.
# Add public keys as HCP Terraform workspace variables (ssh_public_keys map).
# Example: ssh_public_keys = { "work-macbook" = "ssh-ed25519 AAAA..." }
resource "github_user_ssh_key" "this" {
  for_each = var.ssh_public_keys

  title = each.key
  key   = each.value
}

# Account-level GPG keys — used for signed commits verification.
# Add armored public keys as HCP Terraform workspace variables (gpg_public_keys map).
# Generate: gpg --armor --export <key-id>
resource "github_user_gpg_key" "this" {
  for_each = var.gpg_public_keys

  armored_public_key = each.value
}
