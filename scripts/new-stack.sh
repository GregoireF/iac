#!/usr/bin/env bash
# Scaffold a new provider stack.
# Usage: scripts/new-stack.sh <name>
# Called via: just new-stack <name>

set -euo pipefail

NAME="${1:?Usage: new-stack.sh <name>}"
STACK_DIR="terraform/${NAME}"
WFDIR=".github/workflows"

if [ -d "$STACK_DIR" ]; then
  echo "✗ stack '${NAME}' already exists at ${STACK_DIR}" >&2
  exit 1
fi

echo "→ scaffolding ${STACK_DIR}/"

mkdir -p "$STACK_DIR"

cat > "${STACK_DIR}/terraform.tf" <<EOF
terraform {
  required_version = ">= $(cut -d. -f1,2 .opentofu-version)"

  required_providers {
    # TODO: add provider source + version constraints
    # Example:
    # github = {
    #   source  = "integrations/github"
    #   version = "~> 6.13"
    # }
  }

  cloud {
    organization = "$(sed -nE 's/^[[:space:]]*organization[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' terraform/github/terraform.tf | head -1)"

    workspaces {
      name = "${NAME}"
    }
  }
}
EOF

cat > "${STACK_DIR}/providers.tf" <<'EOF'
# TODO: configure provider(s) for this stack.
# Example:
# provider "github" {
#   owner = var.github_owner
#
#   app_auth {
#     id              = var.github_app_id
#     installation_id = var.github_app_installation_id
#     pem_file        = var.github_app_pem_file
#   }
# }
EOF

cat > "${STACK_DIR}/variables.tf" <<'EOF'
# Input variables for this stack.
EOF

cat > "${STACK_DIR}/locals.tf" <<'EOF'
locals {
}
EOF

cat > "${STACK_DIR}/outputs.tf" <<'EOF'
# Outputs for this stack.
EOF

echo "→ scaffolding GHA caller workflows"

cat > "${WFDIR}/tofu-${NAME}-plan.yml" <<EOF
name: "opentofu · ${NAME} · plan"

on:
  pull_request:
    branches: [main]
    paths:
      - "terraform/${NAME}/**"
      - "modules/**"

permissions:
  contents: read
  pull-requests: write

jobs:
  plan:
    uses: ./.github/workflows/_tofu-plan.yml
    with:
      stack: terraform/${NAME}
    secrets:
      TF_API_TOKEN: \${{ secrets.TF_API_TOKEN }}
EOF

cat > "${WFDIR}/tofu-${NAME}-apply.yml" <<EOF
name: "opentofu · ${NAME} · apply"

on:
  push:
    branches: [main]
    paths:
      - "terraform/${NAME}/**"
      - "modules/**"

permissions:
  contents: read

# Never two applies of the same stack at once, never cancel one in progress
concurrency:
  group: tofu-${NAME}-apply
  cancel-in-progress: false

jobs:
  apply:
    uses: ./.github/workflows/_tofu-apply.yml
    with:
      stack: terraform/${NAME}
    secrets:
      TF_API_TOKEN: \${{ secrets.TF_API_TOKEN }}
EOF

echo ""
echo "✓ stack '${NAME}' ready."
echo ""
echo "  1. edit ${STACK_DIR}/terraform.tf  — set required_providers"
echo "  2. edit ${STACK_DIR}/providers.tf  — configure provider(s)"
echo "  3. edit ${STACK_DIR}/variables.tf  — add input variables"
echo "  4. create HCP Terraform workspace '${NAME}' and set workspace variables"
echo "  5. run: just plan ${NAME}"
