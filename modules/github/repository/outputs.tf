output "name" {
  description = "Repository name."
  value       = github_repository.this.name
}

output "html_url" {
  description = "Repository URL."
  value       = github_repository.this.html_url
}

output "ssh_clone_url" {
  description = "SSH clone URL."
  value       = github_repository.this.ssh_clone_url
}

output "http_clone_url" {
  description = "HTTPS clone URL."
  value       = github_repository.this.http_clone_url
}

output "node_id" {
  description = "GraphQL node ID."
  value       = github_repository.this.node_id
}
