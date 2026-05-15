config {
  format           = "compact"
  call_module_type = "local"
}

# GitHub provider rules
plugin "github" {
  enabled = true
  version = "0.26.0"
  source  = "github.com/integrations/tflint-ruleset-github"
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
