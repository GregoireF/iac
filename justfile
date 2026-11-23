# justfile — task runner for the iac repository
# Install: https://github.com/casey/just
# Usage:   just <recipe>   |   just --list

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load

# Pick a recipe in an interactive menu (fzf), or list them when not in a terminal
default:
    #!/usr/bin/env bash
    if [ -t 0 ] && [ -t 1 ] && command -v fzf >/dev/null; then
      just --choose --chooser "fzf --height=60% --layout=reverse --prompt='just › ' --preview='just --show {}' --preview-window=right,60%"
    else
      just --list --unsorted
    fi

# ─── Self-service ─────────────────────────────────────────────────────────────

# Turn a validated request issue (label request:ready) into a signed commit and a pull request
request issue:
    scripts/request.sh {{ issue }}

# ─── Setup ────────────────────────────────────────────────────────────────────

# First-time setup: git hooks (tools come from `just workstation`)
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "→ tools: tofu $(tofu version | head -1 | awk '{print $2}') (expected v$(cat .opentofu-version))"
    echo "→ pre-commit hooks (including commit-msg stage)"
    pre-commit install --install-hooks
    pre-commit install --hook-type commit-msg
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

# Inject terraform-docs into every module README (.terraform-docs.yml)
docs:
    scripts/terraform-docs.sh

# Docs quality: markdownlint, typos, dead links, every mermaid diagram renders (same as CI)
docs-lint *args:
    scripts/check-docs.sh {{ args }}

# Check that module docs are up to date (same as CI)
docs-check: docs
    git diff --exit-code -- modules/

# ─── Policy, Kubernetes, Ansible, workflows ───────────────────────────────────

# OPA unit tests for the OpenTofu plan policies
policy:
    opa test policies/opentofu -v

# Render deployed overlays, then kubeconform + Kyverno (same script as CI)
k8s:
    scripts/check-manifests.sh

# Note: ANSIBLE_CONFIG is explicit because Ansible ignores ansible.cfg in a
# world-writable directory such as /mnt/d under WSL.

# ansible-lint, production profile
ansible-lint:
    cd ansible && ANSIBLE_CONFIG=ansible.cfg ansible-lint --profile production

# Molecule: workstation role in a Debian trixie container (create, converge, idempotence, verify)
molecule:
    cd ansible/roles/workstation && molecule test

# Lint GitHub Actions workflows (syntax + security)
gha:
    actionlint
    zizmor --min-severity medium .github/workflows

# Check commit messages on the branch vs origin/main (no co-author trailer, Signed-off-by)
commits base="origin/main":
    #!/usr/bin/env bash
    set -euo pipefail
    tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
    for c in $(git rev-list "{{ base }}..HEAD"); do
      git log -1 --format=%B "$c" >"$tmp"
      scripts/check-commit-msg.sh "$tmp" || { echo "✗ $c"; exit 1; }
    done
    echo "✓ commits OK"

# ─── Local cluster (k3d + Flux) ───────────────────────────────────────────────

# Create/refresh the k3d cluster and reconcile kubernetes/ through Flux
up:
    cd ansible && ANSIBLE_CONFIG=ansible.cfg ansible-playbook playbooks/cluster.yml

# Delete the local cluster and its registry
down:
    k3d cluster delete iac || true
    k3d registry delete k3d-iac-registry || true

# Provision the WSL workstation tools (idempotent)
workstation:
    cd ansible && ANSIBLE_CONFIG=ansible.cfg ansible-playbook playbooks/workstation.yml

# ─── All checks (mirrors CI) ──────────────────────────────────────────────────

# Fast gates, no cluster: everything CI runs on a pull request except k8s-e2e
check: fmt-check validate lint test policy k8s ansible-lint gha security
    @echo "✓ All checks passed."

# Full gates including the k3d + Flux end-to-end run
check-all: check up
    @echo "✓ All checks + e2e passed."

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
