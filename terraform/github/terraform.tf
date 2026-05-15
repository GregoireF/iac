terraform {
  # OpenTofu — open-source IaC engine (MPL-2 licence, fork post-HashiCorp BSL).
  # https://opentofu.org
  required_version = ">= 1.9"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # HCP Terraform remote backend — runs plan/apply on TFC infrastructure.
  # OpenTofu is compatible with the HCP Terraform cloud block.
  # Sensitive vars (GitHub App credentials) are stored as workspace variables in TFC,
  # never exposed in GitHub Actions.
  #
  # Setup:
  #   1. Create a TFC organization at app.terraform.io
  #   2. Create a workspace named "github" (execution mode: Remote)
  #   3. Replace "YOUR_TFC_ORG" below with your org name
  #   4. Store sensitive variables in TFC workspace settings (see variables.tf)
  #   5. Create a TFC team token → add as GitHub secret TF_API_TOKEN
  #
  # Alternative: Spacelift (natively supports OpenTofu, no HashiCorp dependency).
  cloud {
    organization = "YOUR_TFC_ORG" # TODO: replace

    workspaces {
      name = "github"
    }
  }
}
