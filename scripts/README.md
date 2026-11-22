# scripts

Helpers shared by `just` and CI, so a check behaves the same in both places.

| Script | Used by | Does |
|---|---|---|
| `wsl/new-distro.ps1` | you, once (Windows) | imports `debian:trixie` (pinned digest) as the `iac` WSL distribution, installs uv and ansible-core, runs the playbooks (`-WithCluster`, `-Recreate`, `-SkipProvision`) |
| `check-commit-msg.sh` | commit-msg hook, `just commits`, `commit-policy.yml` | rejects co-author / generated-by trailers, requires the author's own `Signed-off-by` |
| `check-manifests.sh` | `just k8s`, `policy.yml` | renders deployed overlays, kubeconform (with Flux CRDs), Kyverno |
| `check-docs.sh` | `just docs-lint`, `docs-quality.yml` | markdownlint, typos, lychee, renders every Mermaid block |
| `terraform-docs.sh` | pre-commit hook, `just docs`, `docs.yml` | injects terraform-docs into every module README |
| `request.py` | `requests.yml`, `request.sh` | parses and validates a request form, applies it to the working tree (standard library only) |
| `request.sh` | `just request <n>` | re-validates a `request:ready` issue on a branch from `origin/main`, signed commit, pull request |
| `new-stack.sh` | `just new-stack <name>` | scaffolds an OpenTofu stack and its plan/apply workflows ([guide](../docs/how-to/add-a-provider-stack.md)) |

Shell scripts must be committed with the executable bit (`git update-index --chmod=+x`) and pass shellcheck.
