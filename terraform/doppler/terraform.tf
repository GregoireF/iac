terraform {
  required_version = ">= 1.9"

  required_providers {
    doppler = {
      # OpenTofu registry does not carry dopp-eng/doppler — use Terraform registry explicitly.
      source  = "registry.terraform.io/dopp-eng/doppler"
      version = "~> 0.10"
    }
  }

  # Separate HCP Terraform workspace from the github stack.
  # Store DOPPLER_TOKEN as a sensitive workspace variable in HCP Terraform.
  cloud {
    hostname     = "app.terraform.io"
    organization = "gregoiref"

    workspaces {
      name = "doppler"
    }
  }
}
