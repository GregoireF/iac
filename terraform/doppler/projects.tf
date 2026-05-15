resource "doppler_project" "this" {
  for_each = local.projects

  name        = each.key
  description = each.value.description
}

resource "doppler_config" "this" {
  for_each = local.project_configs

  project = each.value.project
  name    = each.value.config

  depends_on = [doppler_project.this]
}

# ---------------------------------------------------------------------------
# Service tokens — one per config, used in CI/CD and local dev.
# Tokens are outputs (sensitive) so they can be fed into GitHub Actions
# secrets via the github stack or manually via the Doppler dashboard sync.
#
# Doppler's native GitHub sync (recommended):
#   Doppler dashboard → Project → Config → Integrations → GitHub Secrets
#   Set once per project; Doppler auto-pushes on every secret change.
# ---------------------------------------------------------------------------
resource "doppler_service_token" "ci" {
  for_each = {
    for k, v in local.project_configs : k => v
    if v.config == "ci"
  }

  project = each.value.project
  config  = each.value.config
  name    = "github-actions"
  access  = "read"

  depends_on = [doppler_config.this]
}
