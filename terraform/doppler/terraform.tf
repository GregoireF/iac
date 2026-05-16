terraform {
  required_version = ">= 1.9"

  required_providers {
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "~> 1.0"
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
