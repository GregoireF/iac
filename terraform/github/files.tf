# The profile README was bootstrapped by Terraform but ownership has moved to
# the GregoireF/GregoireF repo and its own workflows (metrics.yml,
# update-projects.yml, update-now.yml). The removed block drops the resource
# from state without deleting the file so Terraform never overwrites it again.
removed {
  from = github_repository_file.profile_readme

  lifecycle {
    destroy = false
  }
}
