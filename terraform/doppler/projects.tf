resource "doppler_project" "this" {
  for_each = local.projects

  name        = each.key
  description = each.value.description
}

# Doppler auto-creates dev/stg/prd environments — only ci needs explicit creation.
resource "doppler_environment" "ci" {
  for_each = local.projects

  project    = each.key
  slug       = "ci"
  name       = "CI/CD"
  depends_on = [doppler_project.this]
}

# ---------------------------------------------------------------------------
# Service tokens — one per project for the ci config.
# Feed into GitHub Actions secrets via Doppler's native GitHub sync
# (Doppler dashboard → Project → Config → Integrations → GitHub Secrets)
# or store manually as a GitHub Actions secret.
# ---------------------------------------------------------------------------
resource "doppler_service_token" "ci" {
  for_each = local.projects

  project    = each.key
  config     = "ci"
  name       = "github-actions"
  access     = "read"
  depends_on = [doppler_environment.ci]
}
