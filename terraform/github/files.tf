# Inject the GitHub profile README into the GregoireF/GregoireF special repo.
# GitHub displays this README on the public profile page.
resource "github_repository_file" "profile_readme" {
  repository          = module.repository["GregoireF"].name
  branch              = "main"
  file                = "README.md"
  content             = file("${path.module}/templates/profile-readme.md")
  commit_message      = "chore: update profile README [skip ci]"
  overwrite_on_create = true

  lifecycle {
    ignore_changes = [commit_sha]
  }

  depends_on = [module.repository]
}
