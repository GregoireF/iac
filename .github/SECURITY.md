# Security Policy

## Reporting a vulnerability

**Do not open a public issue for security vulnerabilities.**

Use GitHub's private security advisory feature instead:
**Security → Report a vulnerability** (top of this page).

Alternatively, email: gfavreau.wrprojects@gmail.com

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
| Dependency updates | Dependabot weekly — patch/minor auto-merged, major labelled `priority:high` |
| Branch protection | Conventional commits ruleset + required status checks |
| OSSF Scorecard | Weekly scoring — results in GitHub Security tab |
| Least privilege | GitHub Actions permissions declared per-workflow |
| No direct pushes | All changes go through PRs with automated plan + review |
