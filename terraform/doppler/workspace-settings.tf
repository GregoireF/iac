resource "tfe_workspace_settings" "doppler" {
  workspace_id        = data.tfe_workspace.doppler.id
  global_remote_state = true
}

data "tfe_workspace" "doppler" {
  name         = "doppler"
  organization = "gregoiref"
}
