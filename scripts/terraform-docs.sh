#!/usr/bin/env bash
# Inject terraform-docs into the README of every module (config: .terraform-docs.yml).
# Shared by `just docs`, the pre-commit hook and .github/workflows/docs.yml.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

for mod in modules/*/*/; do
  [ -f "$mod/variables.tf" ] || continue
  terraform-docs --config "$root/.terraform-docs.yml" "$mod" >/dev/null
  echo "→ $mod"
done
