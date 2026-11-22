# policies

Independent safety nets, checked by `just policy` and `just k8s` (CI: `policy.yml`).

| Path | Engine | Applies to |
|---|---|---|
| `opentofu/github.rego` + `github_test.rego` | OPA, Rego v1 | OpenTofu plans (JSON) |
| `kubernetes/baseline.yaml` | Kyverno 1.20 `ValidatingPolicy` (CEL) | rendered Kustomize overlays |

Every rule, its intent and its status: [Policies reference](../docs/reference/policies.md).
