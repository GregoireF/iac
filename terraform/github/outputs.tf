output "repositories" {
  description = "Managed GitHub repositories — URLs and node IDs for cross-stack reference."
  value = {
    for name, mod in module.repository : name => {
      url      = mod.html_url
      ssh_url  = mod.ssh_clone_url
      http_url = mod.http_clone_url
      node_id  = mod.node_id
    }
  }
}

output "actions_variables" {
  description = "Repository-level Actions variables managed by this stack."
  value = {
    for k, v in github_actions_variable.github_owner : k => v.variable_name
  }
}

output "label_ids" {
  description = "Composite label keys (repo:label) mapped to GitHub label etags."
  value = {
    for k, v in github_issue_label.standard : k => v.etag
  }
}
