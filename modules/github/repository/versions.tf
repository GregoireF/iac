terraform {
  required_version = ">= 1.13"

  required_providers {
    # Without this block OpenTofu infers the legacy "hashicorp/github" source for the
    # module, so callers ended up installing two GitHub providers (tflint: terraform_required_providers).
    github = {
      source  = "integrations/github"
      version = ">= 6.13"
    }
  }
}
