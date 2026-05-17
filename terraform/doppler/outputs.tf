output "projects" {
  description = "Managed Doppler projects."
  value       = { for k, v in doppler_project.this : k => v.name }
}

output "ci_tokens" {
  description = "CI service tokens per project. Explicitly non-sensitive for cross-workspace tfe_outputs access."
  value       = nonsensitive({ for k, v in doppler_service_token.ci : k => v.key })
}
