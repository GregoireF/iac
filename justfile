# justfile — task runner for the iac repository
# Install: https://github.com/casey/just
# Usage:   just <recipe>   |   just --list

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load

# List all available recipes
default:
    @just --list --unsorted

# ─── Setup ────────────────────────────────────────────────────────────────────

# First-time setup: install all tools and hooks
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "→ OpenTofu (tenv)"
    tenv tofu install
    tenv tofu use "$(cat .opentofu-version)"
    echo "→ pre-commit hooks (including commit-msg stage)"
    pre-commit install --install-hooks
    pre-commit install --hook-type commit-msg
    echo "→ Go dependencies"
    cd tests && go mod tidy
    echo ""
    echo "✓ Setup complete. Run 'just check' to validate everything."

# ─── Format ───────────────────────────────────────────────────────────────────

# Format all HCL files in-place
fmt:
    tofu fmt -recursive terraform/ modules/

# Check formatting without modifying files (used in CI)
fmt-check:
    tofu fmt -check -recursive terraform/ modules/

# ─── Validate & Lint ──────────────────────────────────────────────────────────

# Validate HCL syntax in every stack
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    for stack in terraform/*/; do
      echo "→ $stack"
      (cd "$stack" && tofu init -backend=false -input=false -no-color >/dev/null && tofu validate -no-color) || exit 1
    done

# Run tflint on every stack
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    for stack in terraform/*/; do
      echo "→ $stack"
      tflint --chdir "$stack"
    done

# ─── Tests ────────────────────────────────────────────────────────────────────

# Run tofu test unit tests for all modules (no API calls — uses mock_provider)
test:
    #!/usr/bin/env bash
    set -euo pipefail
    found=0
    for mod in modules/*/*; do
      if [ -d "$mod/tests" ]; then
        found=1
        echo "→ $mod"
        (cd "$mod" && tofu init -backend=false -input=false -no-color >/dev/null && tofu test -no-color) || exit 1
      fi
    done
    [ "$found" -eq 1 ] || echo "No test directories found."

# Run Terratest integration tests (creates real GitHub resources — slow)
test-integration filter="TestGitHub":
    cd tests && go test -v -run "{{ filter }}" -timeout 15m ./...

# ─── Security ─────────────────────────────────────────────────────────────────

# Run Trivy IaC scan
trivy:
    trivy config --severity HIGH,CRITICAL --exit-code 1 --quiet .

# Run Checkov policy scan
checkov:
    checkov -d . --framework terraform --compact --quiet

# Run all security scans
security: trivy checkov

# ─── Docs ─────────────────────────────────────────────────────────────────────

# Generate terraform-docs for all modules
docs:
    #!/usr/bin/env bash
    set -euo pipefail
    for mod in modules/*/*; do
      if [ -f "$mod/variables.tf" ]; then
        echo "→ $mod"
        terraform-docs markdown table --output-file README.md "$mod"
      fi
    done

# Check that docs are up-to-date (fails if terraform-docs would make changes)
docs-check:
    #!/usr/bin/env bash
    set -euo pipefail
    for mod in modules/*/*; do
      if [ -f "$mod/variables.tf" ]; then
        echo "→ $mod"
        terraform-docs markdown table --output-file README.md "$mod"
      fi
    done
    git diff --exit-code modules/

# ─── All checks (mirrors CI) ──────────────────────────────────────────────────

# Run all local checks: fmt, validate, lint, test, security
check: fmt-check validate lint test security
    @echo "✓ All checks passed."

# ─── Stacks ───────────────────────────────────────────────────────────────────

# Plan a stack: just plan github
plan stack:
    cd terraform/{{ stack }} && tofu init -no-color && tofu plan -no-color

# Apply a stack: just apply github
apply stack:
    @echo "⚠ Applying {{ stack }} — confirm? [y/N]"
    @read -r ans && [ "$$ans" = "y" ] || exit 0
    cd terraform/{{ stack }} && tofu init -no-color && tofu apply -no-color

# Apply without confirmation prompt: just apply-auto github
apply-auto stack:
    cd terraform/{{ stack }} && tofu init -no-color && tofu apply -auto-approve -no-color

# ─── Commit ───────────────────────────────────────────────────────────────────

# Interactive conventional commit (czg > git commit)
commit:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v czg >/dev/null 2>&1; then
      czg
    elif command -v npx >/dev/null 2>&1; then
      npx czg
    else
      echo "czg not found — falling back to git commit"
      git commit
    fi

# ─── Generators ───────────────────────────────────────────────────────────────

# Scaffold a new provider stack: just new-stack cloudflare
new-stack name:
    scripts/new-stack.sh {{ name }}

# ─── Maintenance ──────────────────────────────────────────────────────────────

# Remove all .terraform directories and lock files (keeps .terraform.lock.hcl)
clean:
    find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
    find . -name "crash.log" -delete 2>/dev/null || true
    @echo "✓ Cleaned."

# Show OpenTofu version in use
version:
    tofu version
    go version
    python3 --version
    terraform-docs --version
    tflint --version
    trivy --version | head -1
