module "repository" {
  source   = "../../modules/github/repository"
  for_each = local.repositories

  owner  = var.github_owner
  name   = each.key
  config = each.value
}
