locals {
  # ---------------------------------------------------------------------------
  # Doppler projects.
  # One project per logical workload / GitHub repository.
  # Doppler auto-creates dev/stg/prd environments on project creation.
  # The ci environment is created explicitly below.
  # ---------------------------------------------------------------------------
  projects = {
    iac = {
      description = "Secrets for the iac repository (IaC, CI/CD tokens)."
    }
    utils = {
      description = "Secrets for the utils repository."
    }
    telly = {
      description = "Secrets for the telly repository (the key that signs the channel list)."
    }
  }
}
