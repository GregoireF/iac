provider "github" {
  owner = var.github_owner

  # GitHub App auth — ephemeral credentials, no expiry, least-privilege scopes.
  # Credentials are stored as sensitive workspace variables in HCP Terraform.
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    # HCP Terraform stores multi-line variables with literal \n — normalize to real newlines.
    pem_file        = replace(var.github_app_pem_file, "\\n", "\n")
  }
}
