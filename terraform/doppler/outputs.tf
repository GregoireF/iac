output "projects" {
  description = "Managed Doppler projects."
  value       = { for k, v in doppler_project.this : k => v.name }
}

output "ci_tokens" {
  description = "CI service tokens per project. Read-only tokens — non-sensitive so tfe_outputs can read them cross-workspace without global remote state."
  value       = { for k, v in doppler_service_token.ci : k => v.key }
}
