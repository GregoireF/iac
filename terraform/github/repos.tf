module "repository" {
  # Git source so HCP Terraform remote execution can fetch the module.
  # Local path (../../modules/github/repository) is not included in the
  # CLI-driven upload tarball — only files within terraform/github/ are sent.
  source   = "git::https://github.com/GregoireF/iac.git//modules/github/repository?ref=main&depth=1"
  for_each = local.repositories

  owner  = var.github_owner
  name   = each.key
  config = each.value
}
