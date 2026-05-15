# GitHub Copilot instructions — iac

This repository is an Infrastructure as Code (IaC) engineering lab managed with **OpenTofu**.

---

## Stack

- **IaC engine**: OpenTofu >= 1.9 (NOT Terraform — use `tofu` CLI)
- **State backend**: HCP Terraform (remote execution mode)
- **Auth**: GitHub App (ephemeral tokens via `app_auth {}` block)
- **CI/CD**: GitHub Actions
- **AI workflows**: GitHub Models API (`GITHUB_TOKEN`, no external key)

---

## Project structure

```
terraform/<provider>/   ← one stack per provider (github, cloudflare, hetzner...)
modules/<provider>/<name>/  ← reusable modules
.github/workflows/      ← naming: <engine>-<provider>-<action>.yml
.github/scripts/        ← Python automation scripts (stdlib only, no pip)
```

---

## OpenTofu conventions

- Use `tofu` CLI, not `terraform`
- Always set `required_version = ">= 1.9"` in `terraform {}` block
- Pin provider versions with `~>` (patch-compatible): `version = "~> 6.0"`
- Format with `tofu fmt` before committing
- Use `for_each` over `count` for named resources
- Use `locals {}` as the single source of truth for resource definitions
- Never use `count` on modules — use `for_each = { key = config }`
- Add `prevent_destroy = true` on any resource that would be catastrophic to lose
- Mark sensitive variables with `sensitive = true`
- Use `dynamic` blocks for optional rule groups

## Security rules

- Never commit secrets, tokens, PEM keys, or `.tfvars` files
- Sensitive values live in HCP Terraform workspace variables only
- `vulnerability_alerts = true` on every `github_repository` resource
- Validate `visibility` before applying (public repos are public)

## Naming conventions

- Terraform resource keys: `snake_case`
- Module source paths: `../../modules/<provider>/<name>`
- Locals map keys: `snake_case` matching the actual resource name (e.g., repo name)
- Label composite keys: `"<repo>:<label>"` format for flattened for_each

## Python scripts (.github/scripts/)

- Standard library only — no `pip install`, no `requirements.txt`
- Use `urllib.request` for HTTP, `json` for parsing
- Use environment variables for all external config (never hardcode)
- GitHub Models API: POST to `https://models.inference.ai.azure.com/chat/completions` with `GITHUB_TOKEN`
- Default model: `gpt-4o-mini` for speed/cost, `gpt-4o` for complex reasoning

## GitHub Actions

- Workflow filename: `<engine>-<provider>-<action>.yml`
- Always set `concurrency` to prevent parallel conflicting runs
- `cancel-in-progress: false` on apply/destructive jobs
- Use `permissions` minimal scope (principle of least privilege)
- Path filters on `on.push.paths` / `on.pull_request.paths` to avoid unnecessary runs
