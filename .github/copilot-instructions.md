# GitHub Copilot instructions — iac

A one-maintainer platform as code: OpenTofu for GitHub, Ansible for the workstation and cluster bootstrap,
Flux for Kubernetes, OPA and Kyverno for policies. Read [docs/README.md](../docs/README.md) first.

## Stack

- **IaC engine**: OpenTofu `>= 1.13`, version in `.opentofu-version` — use the `tofu` CLI, never `terraform`
- **State backend**: HCP Terraform (remote execution, organisation `gregoiref`) until phase 2 of `docs/ROADMAP.md`
- **Auth**: GitHub App (ephemeral tokens via the `app_auth {}` block)
- **Workstation**: WSL distribution `iac` built by `scripts/wsl/new-distro.ps1` and `ansible/`
- **Kubernetes**: k3d (k3s) + Flux 2.10, `kubernetes/` pushed as an OCI artifact
- **Secrets**: Doppler today, SOPS + age decided (roadmap D8)

## Project structure

```text
terraform/<stack>/          one OpenTofu root module per provider (github, doppler)
modules/<provider>/<name>/  reusable modules, with tests/ and a terraform-docs README
ansible/                    playbooks and roles (workstation, k3d_cluster, flux_bootstrap)
kubernetes/                 Flux layout: clusters/, infrastructure/, apps/
policies/                   OPA (plans) and Kyverno (manifests)
scripts/                    checks shared by just and CI
.github/workflows/          <engine>-<provider>-<action>.yml for stacks
```

## OpenTofu conventions

- `required_version = ">= 1.13"`; providers pinned with `~>`: `version = "~> 6.13"`
- Lock files for `linux_amd64`, `linux_arm64`, `darwin_arm64`, `windows_amd64`; none inside `modules/`
- Module git sources pinned to an immutable tag (`ref=vX.Y.Z`), never `ref=main`
- `for_each` over `count` for named resources; `locals {}` as the single source of truth
- `prevent_destroy` on anything catastrophic to lose; `sensitive = true` on secrets
- Every module change comes with a `tofu test` case (`mock_provider`, no API calls)

## Security rules

- Never commit secrets, tokens, PEM keys or `.tfvars`
- Vulnerability alerts on every active repository through `github_repository_vulnerability_alerts`
  (the `vulnerability_alerts` argument is deprecated since provider 6.12)
- Check `visibility` before applying: public repositories are public

## GitHub Actions

- Actions pinned by full commit SHA with a version comment; `actions/checkout` with `persist-credentials: false`
- Inputs and expressions reach shells through `env:`, never `${{ }}` inside `run:`
- Explicit secrets for reusable workflows, never `secrets: inherit`
- `concurrency` on every workflow; `cancel-in-progress: false` on applies
- Least-privilege `permissions`; path filters on `push` and `pull_request`
- Exception: `security-scan` has no path filter on `pull_request` (OpenSSF Scorecard SAST check)
- Tool versions carry a `# renovate:` comment

## Commits

- Conventional Commits, lower-case subject; `git commit -s`; SSH-signed
- One human author: no `Co-authored-by`, `Generated-by` or `Assisted-by` trailer, no "Generated with" footer
- Run `just check` before pushing; it mirrors CI
