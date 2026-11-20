config {
  format           = "compact"
  call_module_type = "local"
}

# Core OpenTofu/Terraform language rules (the rules below belong to this ruleset).
# The former "github" plugin pointed to github.com/integrations/tflint-ruleset-github,
# which does not exist, so `tflint --init` failed.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
  version = "0.17.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

# Core OpenTofu/Terraform rules
rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}
