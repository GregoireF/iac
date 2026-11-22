# Security Policy

## Reporting a vulnerability

**Do not open a public issue for security vulnerabilities.**

Use GitHub's private security advisory feature instead:
**Security → Report a vulnerability** (top of this page).

Alternatively, email: <gfavreau.wrprojects@gmail.com>

### What to include

- Description of the issue and its potential impact
- Steps to reproduce or a proof-of-concept (if safe to share)
- Affected file(s) and line numbers if applicable

### Response timeline

| Step | Target |
|---|---|
| Acknowledgement | 48 hours |
| Severity assessment | 7 days |
| Fix / remediation | Depends on severity — critical issues are prioritised |

---

## Security features in this repository

| Control | Implementation |
|---|---|
| Authentication | GitHub App with ephemeral tokens — no long-lived PATs |
| Secrets storage | HCP Terraform workspace variables (encrypted at rest) |
| Secret detection | `detect-private-key` pre-commit hook + Trivy |
| IaC scanning | Trivy + Checkov on every PR (SARIF → GitHub Security tab) |
| Dependency updates | Renovate weekly — patch/minor/digest auto-merged after green CI, majors reviewed |
| Branch protection | Ruleset on `main`: no deletion, no force-push, pull request and status checks (owner bypass only) |
| Commit integrity | SSH-signed, signed-off commits from a single human author (hook + `commit-policy.yml`) |
| Workflow audit | zizmor + actionlint: SHA-pinned actions, no template injection, no persisted credentials |
| OSSF Scorecard | Weekly scoring — results in GitHub Security tab |
| Least privilege | Read-only workflow permissions by default; each job asks for what it writes |
| Reviewed infrastructure | Changes to `terraform/` and `modules/` go through a pull request with the plan posted for review |

Full model: [docs/explanation/security-model.md](../docs/explanation/security-model.md).
