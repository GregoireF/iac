# Roadmap — iac "platform-next"

> One person, zero budget, maximum automation. Everything that can run without a human runs without a human.

Snapshot: 2026-11-20. Versions were read from upstream release APIs on 2026-11-19/20; after that, Renovate owns them.

## Decisions

| # | Decision | Why |
|---|---|---|
| D1 | **Remove the three AI workflows** (issue triage, PR review, changelog) | They call `models.inference.ai.azure.com`; GitHub Models was retired on 2026-07-30 ([summary](https://daily.dev/posts/github-models-is-being-fully-retired-on-july-30-2026-bz8saavyw), [migration guide](https://www.cloudkaramchari.com/blog/github-models-retirement-migration-guide/)). `ai-pr-review` failed 4/4 runs since 2026-11-14 with `Name or service not known`. Replaced by deterministic checks. |
| D2 | **100 % OpenTofu: leave HCP Terraform** | Encrypted state ([OpenTofu state encryption](https://opentofu.org/docs/language/state/encryption), `pbkdf2` + `aes_gcm`) stored **in this repository** on a dedicated `tfstate` branch. Locking = GitHub Actions `concurrency` group (single maintainer). No external account. |
| D3 | **Renovate replaces Dependabot** | One grouped weekly PR for every non-major update, auto-merged when CI is green; majors and pinned-hash tools wait for a human. Regex managers cover every `# renovate:` annotation, `==` PyPI pin and `image:tag@digest` (checked with a local `--dry-run=extract`: 54 regex dependencies). |
| D4 | **k3d** (k3s in Docker) for Kubernetes, locally and in CI | Same distribution as the target self-hosted k3s cluster, with Traefik and local-path storage built in ([k3d](https://k3d.io), [k3s networking](https://docs.k3s.io/networking/networking-services)); its own registry lets Flux reconcile uncommitted changes as an OCI artifact ([Flux OCI cheatsheet](https://fluxcd.io/flux/cheatsheets/oci-artifacts/)). Replaces kind (first choice). |
| D5 | **Flux** for GitOps | Everything declared in Git; image and chart updates flow through Renovate ([repository structure](https://fluxcd.io/flux/guides/repository-structure/)). |
| D6 | **Ansible** for the WSL Debian workstation and the cluster bootstrap; `workstation` tested with **Molecule**, cluster roles by the k3d e2e run | Reproducible workstation; every role proven in CI ([Molecule](https://ansible.readthedocs.io/projects/molecule/)). |
| D7 | Import CI hygiene from `ship-it` / `kiwa` | zizmor + actionlint, dependency-review, commit policy, labels-as-code, `AGENTS.md`. |
| D8 | **SOPS + age replace Doppler** | Secrets encrypted in Git, readable by OpenTofu ([carlpett/sops provider](https://registry.terraform.io/providers/carlpett/sops/latest/docs)) and Flux ([Flux SOPS guide](https://fluxcd.io/flux/guides/mozilla-sops/)). No external account. |
| D9 | **No CI bot commits** | terraform-docs runs in a pre-commit hook; CI only checks that docs are current. Every commit on `main` has one signed human author ([ADR 0002](adr/0002-solo-flow.md)). |
| D10 | **Stacks consume modules by relative path** once HCP Terraform is gone (phase 2) | The `?ref=v1.3.1` git source exists only because HCP uploads `terraform/github/` alone. A relative path removes the release-then-bump step and the stale-module warnings it causes today. |

| D11 | **Local only for now; Talos Linux for the future real cluster**, run in Docker in CI first | No budget. Hetzner raised prices twice in 2026 (1 April, 15 June; CAX11 €4.49 → €5.99/month excl. VAT) and cost-optimized plans were intermittently unavailable ([Hetzner](https://docs.hetzner.com/general/infrastructure-and-availability/price-adjustment/), [Northflank](https://northflank.com/blog/hetzner-cloud-server-price-increases), [Bitdoze](https://www.bitdoze.com/hetzner-cloud-cost-optimized-plans/)). Talos is immutable and API-driven (no SSH), the secure-bootstrap target; Talos 1.14 ships Kubernetes 1.37 by default, same minor as our k3s (to confirm on the official releases page). |
| D12 | **Networking = Kubernetes networking**: Cilium (CNI, NetworkPolicies, Hubble, Gateway API) on the Talos cluster | Real, testable locally and in CI at no cost; a cloud VPC module would never be applied. |
| D13 | **Observability = LGTM + OpenTelemetry**: Prometheus, Loki, Tempo, Grafana, OTel Collector | The standard stack visitors and recruiters recognise. Replaces the Victoria-stack proposal. |
| D14 | **Self-service in this repo**: issue forms + labels (IssueOps), owner-only `/plan` `/apply` `/e2e` `/docs` PR commands, interactive `just` menu | Audience = the maintainer "later and tired" and read-only visitors. iac is public: every writing workflow checks that the actor is the owner. A separate requests repo only once third parties file requests (ADR 0001 rule: security boundary). |
| D15 | **Golden paths**, in order: new app on the cluster, new GitHub repo, new OpenTofu module, ephemeral `/preview` environment | Each is a form or command that ends in a reviewed PR. |
| D16 | **Supply chain**: GitHub artifact attestations, cosign-signed OCI artifacts verified by Flux, SBOM + scan, OpenSSF Scorecard ≥ 9 | Every artifact Flux deploys is signed and traceable to its workflow run. |
| D17 | **Repository split: modules only** — one `terraform-<provider>-<name>` repo per published module | Registries require that name; an outside consumer is an ADR 0001 criterion. observability-kit and talos-cluster stay folders here (publishable as OCI artifacts). |
| D18 | **Cost**: requests/limits everywhere + lite cluster profile, weekly CI-minutes report, a costed ADR for the paid scenario; OpenCost only with a paid cluster | Public repos run on free GitHub-hosted runners; the self-hosted runner fee announced for March 2026 was postponed ([GitHub changelog](https://github.blog/changelog/2025-12-16-coming-soon-simpler-pricing-and-a-better-experience-for-github-actions/)). No self-hosted runner: it would only exist while the PC is on. |
| D19 | **Parked: Cloudflare** (DNS, Tunnel, Access, Pages/R2) | No budget and no need yet; revisit with the first public service. |

Honest limit: a cluster on the PC only runs **while the PC is on**. Anything that must run 24/7 (Renovate, plans, scans) stays in GitHub Actions, which is free for public repositories.

## Versions (latest on 2026-11-19/20)

| Tool | Before | Now |
|---|---|---|
| OpenTofu | 1.12.0 (`required_version >= 1.9`) | **1.13.9** (`>= 1.13`) — [1.13 notes](https://opentofu.org/blog/opentofu-1-13-0/) |
| integrations/github provider | `~> 6.0` | `~> 6.13` (v6.13.0) |
| DopplerHQ/doppler provider | `~> 1.0` | `~> 1.23` — removed with D8 |
| hashicorp/tfe provider | `~> 0.60` | `~> 0.84` — removed with D2 |
| Go | 1.23 (mise, go.mod) / 1.26.3 (devcontainer) | **1.27.4** everywhere |
| Terratest | 0.47.2 | v2 (`modules/core/v2.0.0`) — import paths to check before bumping |
| testify | 1.9.0 | 1.12.1 |
| tenv / tflint / terraform-docs | 4.12.2 / 0.62.1 / 0.24.0 | 4.16.9 / 0.66.0 / 0.25.1 |
| Trivy / Checkov | 0.70.0 / 3.2.529 | 0.76.2 / 3.4.5 |
| pre-commit / pre-commit-hooks / conventional-pre-commit | 4.6.0 / v5.0.0 / v3.4.0 | 4.7.0 / v6.0.0 / v4.5.0 |
| actions/checkout | v6.0.2 | v7.0.1 (every workflow, SHA-pinned) |
| k3d / k3s | — | v5.9.0 / v1.37.2+k3s1 |
| kubectl / Flux / Helm | — | v1.37.2 / v2.10.0 / v4.3.2 |
| ansible-core / molecule / ansible-lint | — | 2.22.0 / 26.11.0 / 26.11.0 |
| OPA / Conftest / Kyverno / kubeconform | — | 1.22.4 / 0.71.1 / 1.20.0 / 0.8.0 |
| zizmor / actionlint | — | 1.32.0 / 1.7.12 |
| SOPS / age | — | v3.13.3 / v1.3.2 |

## Layout

```
terraform/            OpenTofu stacks (github, doppler) — state encrypted on branch tfstate (phase 2)
modules/              reusable OpenTofu modules (+ tofu test, terraform-docs)
policies/
  opentofu/           OPA/Rego rules on the plan JSON (+ opa test)
  kubernetes/         Kyverno ValidatingPolicies (CEL) on rendered manifests
ansible/
  inventories/        local.yml
  playbooks/          workstation.yml, cluster.yml
  roles/              workstation (+ molecule/), k3d_cluster, flux_bootstrap
kubernetes/           Flux layout
  clusters/local/     entry point reconciled by Flux (OCI artifact from the k3d registry)
  infrastructure/     namespaces (Pod Security), then controllers + observability
  apps/               podinfo (demo), then self-hosted services and your apps
scripts/              wsl/new-distro.ps1, check-commit-msg.sh, check-manifests.sh, terraform-docs.sh
docs/                 ROADMAP, ARCHITECTURE, ADRs
```

## Quality gates

`just check` runs the same commands as CI, inside the `iac` WSL distribution:

| Gate | Local | CI |
|---|---|---|
| tofu fmt / validate / tflint / tofu test | `just fmt-check validate lint test` | `tofu-test.yml`, `_tofu-plan.yml` |
| OPA unit tests | `just policy` | `policy.yml` |
| kubeconform + Kyverno on rendered overlays | `just k8s` → `scripts/check-manifests.sh` | `policy.yml` (same script) |
| ansible-lint (production) / Molecule | `just ansible-lint` / `just molecule` | `ansible.yml` (Molecule with **every** binary) |
| actionlint + zizmor | `just gha` | `zizmor.yml` |
| Trivy + Checkov | `just security` | `security-scan.yml` |
| module docs current | pre-commit hook / `just docs-check` | `docs.yml` (check only) |
| commit policy (no co-author trailer, DCO) | commit-msg hook / `just commits` | `commit-policy.yml` |
| k3d + Flux end to end | `just up` (or `just check-all`) | `k8s-e2e.yml` |

## Phases

1. **Upgrade & autopilot** — done on `feat/platform-next`
   - every pin above bumped; Go and OpenTofu aligned everywhere
   - AI workflows and scripts deleted (D1); Dependabot → Renovate (D3)
   - zizmor + actionlint, dependency-review, commit policy, policy-as-code workflows (D7)
   - zizmor findings fixed in the existing workflows: no template injection, no persisted credentials, no `secrets: inherit`
2. **State migration** (D2, D10): encrypted local backend, `tfstate` branch, plan/apply workflows rewritten, `tfe` removed, modules by relative path. Needs a passphrase secret (`TF_ENCRYPTION_PASSPHRASE`, kept SOPS-encrypted in the repo too).
3. **Ansible** — done: WSL distro bootstrap (`scripts/wsl/new-distro.ps1`), `workstation` role (checksum-verified downloads, idempotent), Molecule in CI.
4. **Kubernetes + Flux** — done: `k3d_cluster` + `flux_bootstrap` roles, `kubernetes/` tree, `k8s-e2e.yml`. Verified locally: every Kustomization Ready, podinfo running under the `restricted` Pod Security Standard.
5. **Self-service** (D14): issue forms + labels, owner-only PR commands, interactive `just` menu.
6. **Secrets & supply chain** (D8, D16): SOPS + age (OpenTofu, Flux), GitHub OIDC in CI, attestations, cosign + Flux verification, SBOM, Scorecard ≥ 9; Doppler stack retired.
7. **Observability** (D13): LGTM + OTel Collector, lite profile for the PC; then Gatus (status), Garage (S3), cert-manager; Longhorn only on real nodes (needs `open-iscsi` on the host, unavailable in k3d).
8. **Talos + Cilium** (D11, D12): machine config as code, Talos-in-Docker cluster in CI with the same Flux tree.
9. **Golden paths** (D15) and the **modules split** (D17).
10. **Docs & showcase**: Starlight site on GitHub Pages with live status (CI, versions, DORA), runbooks, per-folder READMEs + `examples/`, `AGENTS.md`, README rewritten around the new stack.

Still to verify with sources before building: OpenBao status (kept out per D8 anyway), current Cloudflare provider major (D19), IssueOps reference implementations (D14).

## Needed from the maintainer (one-time)

- Install the Renovate GitHub App on the repository (free) — or decide on self-hosted Renovate in Actions.
- Generate the state passphrase (phase 2) and an age key (phase 5).
