# ADR 0002 — Solo flow: local-first, trunk-based, robots for the rest

- Status: proposed (2026-11-20)
- References: *The DevOps Handbook* (Kim, Humble, Debois, Willis, Forsgren) — the "Three Ways": flow, fast feedback, continual learning; *Accelerate* / DORA metrics (deployment frequency, lead time for changes, change failure rate, time to restore).

## Decision

| Practice | How, concretely | Way it serves |
|---|---|---|
| **Local-first** | `just check` runs exactly what CI runs, inside the dedicated WSL distribution `iac` (provisioned by Ansible). Nothing is pushed red. | Flow + fast feedback |
| **Trunk-based** | The owner may push directly to `main` when `just check` is green; CI still runs on `main` and blocks deploy jobs on failure. PRs stay mandatory for bots and for large changes. | Flow (small batches) |
| **Stacks for big work** | `ship-it` stacked PRs only when a change is too big to land in one green commit. | Flow |
| **One robot PR per week** | Renovate groups every non-major update into one PR, auto-merged when green; majors wait. | Fast feedback without noise |
| **Signed, single author** | Every commit signed (SSH) and signed-off; no co-author or generated-by trailer (enforced by a commit-msg hook and a CI check). | Trust / audit |
| **Weekly health issue** | One issue every Monday: drift, failed runs, outdated pins, Scorecard score, DORA metrics across repos. | Continual learning |

## Consequences

- The `iac` ruleset in `terraform/github` must allow the owner's direct pushes while keeping required checks for PRs (to implement and review in the github stack plan).
- Every check needs a local equivalent; a check that only exists in CI is a bug in this ADR.
