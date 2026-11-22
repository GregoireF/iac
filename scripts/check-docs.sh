#!/usr/bin/env bash
# Documentation quality gates, shared by `just docs-lint` and .github/workflows/docs-quality.yml:
#   1. markdownlint-cli2  style          (.markdownlint-cli2.yaml)   — official Docker image
#   2. typos              spelling       (_typos.toml)               — uv tool
#   3. lychee             dead links     (lychee.toml)               — release binary
#   4. mermaid-cli        every ```mermaid block renders              — official Docker image
# Usage: scripts/check-docs.sh [--offline]   (--offline: lychee checks local links only)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
offline=()
[ "${1:-}" = "--offline" ] && offline=(--offline)

# renovate: datasource=docker depName=davidanson/markdownlint-cli2
MARKDOWNLINT_IMAGE="davidanson/markdownlint-cli2:v0.24.2@sha256:c768e94d8bb161c449bde28f60656929ca1f02c3010a405f65c9cac71563a889"
# renovate: datasource=docker depName=minlag/mermaid-cli
MERMAID_IMAGE="minlag/mermaid-cli:12.0.1@sha256:18938e53497376d524e04b1fc0bf7b6d61a491ce9ff7032bb2855d57155acb10"

# Markdown files, without caches, generated output and the templates injected into other repos
# (find, not git ls-files: a Windows-created worktree is unreadable by git inside WSL)
mapfile -t md < <(find . -name '*.md' \
  -not -path './.git/*' -not -path '*/.terraform/*' -not -path './rendered/*' \
  -not -path '*/node_modules/*' -not -path '*/templates/*' -not -path './.lycheecache' | sed 's|^\./||' | sort)

echo "→ markdownlint (${#md[@]} files)"
docker run --rm -v "$root:/workdir:ro" -w /workdir "$MARKDOWNLINT_IMAGE" "${md[@]}"

echo "→ typos"
typos

echo "→ lychee ${offline[*]}"
lychee --no-progress "${offline[@]}" "${md[@]}"

echo "→ mermaid"
out="$(mktemp -d)"; trap 'rm -rf "$out"' EXIT
chmod 0777 "$out"   # the image runs as an unprivileged user
n=0
for f in "${md[@]}"; do
  grep -q '^```mermaid' "$f" || continue
  # one .mmd file per block, named after the source file
  awk -v dir="$out" -v base="$(echo "$f" | tr '/' '_')" '
    /^```mermaid[[:space:]]*$/ { inblk=1; i++; file=sprintf("%s/%s.%d.mmd", dir, base, i); next }
    inblk && /^```[[:space:]]*$/ { inblk=0; close(file); next }
    inblk { print > file }' "$f"
done
for m in "$out"/*.mmd; do
  [ -e "$m" ] || break
  n=$((n + 1))
  if ! docker run --rm -v "$out:/data" "$MERMAID_IMAGE" -q -i "/data/$(basename "$m")" -o "/data/$(basename "$m").svg" >/dev/null 2>"$m.err"; then
    echo "✗ $(basename "$m" .mmd | sed 's/_/\//g')"; sed 's/^/    /' "$m.err" | head -15; exit 1
  fi
done
echo "  $n diagrams render"
echo "✓ docs OK"
