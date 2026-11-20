#!/usr/bin/env bash
# Render every deployed Kustomize overlay, then validate it.
# Shared by `just k8s` and .github/workflows/policy.yml so local and CI never drift.
#   - kubeconform: strict schemas (Flux CRDs via the datreeio CRDs catalog)
#   - Kyverno CLI: iac baseline ValidatingPolicies (policies/kubernetes)
# Bases are skipped: overlays include them, and rendering both duplicates objects
# (the Kyverno CLI panics on a duplicated Namespace).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${RENDERED_DIR:-$root/rendered}"
cd "$root"

rm -rf "$out"
mkdir -p "$out"
for k in kubernetes/clusters/* kubernetes/infrastructure/* kubernetes/apps/*; do
  [ -f "$k/kustomization.yaml" ] || continue
  [ "$(basename "$k")" = base ] && continue
  echo "→ render $k"
  kubectl kustomize "$k" >"$out/$(echo "$k" | tr '/' '_').yaml"
done

echo "→ kubeconform"
kubeconform -strict -summary -ignore-missing-schemas=false \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  "$out/"

echo "→ Kyverno baseline"
kyverno apply policies/kubernetes/ --resource "$out/"
