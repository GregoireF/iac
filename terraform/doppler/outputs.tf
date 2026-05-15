output "projects" {
  description = "Managed Doppler projects."
  value       = { for k, v in doppler_project.this : k => v.name }
}

output "configs" {
  description = "Managed Doppler configs (project/environment pairs)."
  value       = { for k, v in doppler_config.this : k => "${v.project}/${v.name}" }
}

output "ci_tokens" {
  description = "CI service tokens per project. Sensitive — use Doppler dashboard to set GitHub sync or store manually as GitHub secrets."
  sensitive   = true
  value       = { for k, v in doppler_service_token.ci : k => v.key }
}
