provider "doppler" {
  doppler_token = var.doppler_token
}

provider "tfe" {
  # Token is read from TFE_TOKEN environment variable set in HCP Terraform workspace.
}
