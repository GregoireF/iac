provider "github" {
  owner = var.github_owner
  # Token is read from GITHUB_TOKEN environment variable set in HCP Terraform workspace.
}

provider "tfe" {
  # Token is read from TFE_TOKEN environment variable set in HCP Terraform workspace.
}
