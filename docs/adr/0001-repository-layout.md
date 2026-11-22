# ADR 0001 — Repository layout: split only when a rule says so

- Status: accepted (2026-11-20)
- Context: one maintainer, zero budget, goal = minimum friction (few PRs, few releases, fast local checks).

## Rule

A concern gets **its own repository only if at least one of these is true**:

1. **Independent consumers** need to pin it to a version that must not move with everything else.
2. **Different security boundary**: it needs credentials or permissions the rest must not have.
3. **Different release cadence** that would otherwise spam releases/tags of the other repo.
4. **Different lifecycle owner** (another team, an external audience) — not applicable today.

Otherwise it stays in `iac`. Each extra repository costs: its own CI, Renovate PRs, release process, labels, rulesets, docs.

## Decision

| Concern | Where | Rule that applies |
|---|---|---|
| OpenTofu stacks + modules, Ansible, Kubernetes (Flux), policies, docs site | **`iac`** | none of 1–4: one platform, changed together, tested together (`just check`, k8s-e2e) |
| Reusable CI/CD workflows + composite actions for **all** repos (lint, release, deploy) | **new `workflows` repo** (created and governed by `iac`) | **1** — `ship-it`, `kiwa`, `addlicense`, `utils`… pin `@v1`; **3** — workflow releases must not follow every infra change |
| OpenTofu modules published on a registry | **one `terraform-<provider>-<name>` repository per published module** (amended 2026-11-20, ROADMAP D17) | **1** — a registry requires that repository name, and publishing makes outside consumers possible. Modules not meant for publication stay in `iac`. |
| Observability kit, Talos cluster | **folders in `iac`**, publishable as OCI artifacts | none of 1–4 yet (ROADMAP D17) |
| Org-wide community files (`GregoireF/.github`) | keep the existing (empty) repo for GitHub's special-purpose role only | GitHub reads default community files from it; not a place for code |

Rejected:

- **Separate GitOps repo** for `kubernetes/`: no different consumer or boundary; it would double PRs for changes that span Ansible + manifests.
- **One repo per module, for every module**: release overhead for modules nobody else consumes; only published modules get their own repository.
- **Workflows inside `iac`**: every consumer would pin `iac@vX`, and every infra release would bump workflow versions in every repo (rule 3).

## Consequences

- `iac` stays the single place to change the platform; trunk-based, verified locally first (`just check` runs the same steps as CI).
- `workflows` is versioned with major tags (`v1`, moved on release) plus immutable `v1.x.y`; Renovate updates callers in one grouped weekly PR.
- `iac` (terraform/github) creates `workflows`, its rulesets and labels — the platform governs its own tooling.
