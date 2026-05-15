variable "doppler_token" {
  type        = string
  description = "Doppler service token with project:read/write and config:read/write scopes. Store as a sensitive workspace variable in HCP Terraform."
  sensitive   = true
}
