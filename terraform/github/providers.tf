provider "github" {
  owner = var.github_owner
  # Token is read from GITHUB_TOKEN environment variable set in HCP Terraform workspace.
}
