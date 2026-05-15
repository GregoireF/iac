terraform {
  required_version = ">= 1.9"

  required_providers {
    doppler = {
      source  = "dopp-eng/doppler"
      version = "~> 0.10"
    }
  }

  # Separate HCP Terraform workspace from the github stack.
  # Store DOPPLER_TOKEN as a sensitive workspace variable in HCP Terraform.
  cloud {
    organization = "gregoiref"

    workspaces {
      name = "doppler"
    }
  }
}
