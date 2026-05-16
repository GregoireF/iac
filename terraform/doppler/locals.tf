locals {
  # ---------------------------------------------------------------------------
  # Doppler projects.
  # One project per logical workload / GitHub repository.
  # configs: named environments within a project.
  #   ci  → secrets injected into GitHub Actions via Doppler's native GitHub sync
  #   dev → local development
  #   prd → production workloads (if applicable)
  # ---------------------------------------------------------------------------
  projects = {
    iac = {
      description = "Secrets for the iac repository (IaC, CI/CD tokens)."
      configs     = ["ci", "prd"]
    }
    utils = {
      description = "Secrets for the utils repository."
      configs     = ["ci", "dev", "prd"]
    }
  }

  # Flatten projects × configs into a single map for for_each.
  # Key format: "<project>/<config>"
  project_configs = merge([
    for proj_name, proj_cfg in local.projects : {
      for config_name in proj_cfg.configs :
      "${proj_name}/${config_name}" => {
        project = proj_name
        config  = config_name
      }
    }
  ]...)
}
