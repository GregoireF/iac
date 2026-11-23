# Troubleshooting

Every entry below happened while building this platform; the symptom is quoted as it appears.

## Workstation (WSL)

| Symptom | Cause | Fix |
|---|---|---|
| k3s or kind nodes never become Ready; cgroup errors in the node logs | WSL still on cgroup v1 (old WSL) | `wsl --update`, then `wsl --shutdown`; `stat -fc %T /sys/fs/cgroup` must print `cgroup2fs` |
| `the role 'workstation' was not found` | Ansible ignores `ansible.cfg` in a world-writable directory such as `/mnt/d` | Run through `just` (it sets `ANSIBLE_CONFIG=ansible.cfg`) or export it yourself |
| `fatal: not a git repository` inside WSL, on a worktree created from Windows | The worktree's `.git` file holds a Windows path | Run git from Windows for that worktree; scripts here avoid git (they use `find`) |
| `git config --global` fails with `not a git repository` from a playbook | Git still inspects the current directory, here a worktree it cannot read | The role runs git from `$HOME` |
| A tool is missing after a Renovate bump | The stamp for the new version does not exist yet | `just workstation` (idempotent, reinstalls only what changed) |

## Molecule

| Symptom | Cause | Fix |
|---|---|---|
| `Missing expected 'results' in ansible-galaxy cache` | Corrupted galaxy response cache | `rm -rf ~/.ansible/galaxy_cache` |
| `Failed to import the required Python library (requests)` | Molecule runs the `ansible-playbook` on `PATH`, whose environment lacks the Docker SDK | The workstation role injects `docker` and `requests` into the ansible-core uv tool; re-run `just workstation` |
| `Failed to find required executable "rsync"` | The docker driver copies the build context with rsync | Part of the role's apt packages; re-run `just workstation` |
| `invalid reference format` during create | The driver derives an image tag from an `image@sha256:` reference | The scenario uses `pre_build_image: true` and installs Python in `prepare.yml` |

## Kubernetes and Flux

| Symptom | Cause | Fix |
|---|---|---|
| Kyverno CLI panics: `namespaces "apps" already exists` | `base/` and its overlay rendered together duplicate objects | Render overlays only — `scripts/check-manifests.sh` already does |
| `ClusterPolicy` rejected by Kyverno 1.20 | Legacy policy kinds are gone | Write `policies.kyverno.io/v1` `ValidatingPolicy` with CEL |
| Flux source not ready after `just up` | Artifact not pushed, or registry not reachable | `flux get sources oci -A`; the registry is `localhost:5001` on the host and `k3d-iac-registry:5000` in the cluster |

## CI and tooling

| Symptom | Cause | Fix |
|---|---|---|
| `scripts/…sh: Permission denied` in a workflow | File committed without the executable bit (common from Windows) | `git update-index --chmod=+x scripts/<file>.sh` and commit |
| Renovate local run: `RegExp.escape is not a function` | Renovate 44 needs Node.js 24+ | `npx -y -p node@24 -p renovate@<version> -- renovate …` |
| zizmor green locally, red in CI | CI runs the online audits (a GitHub token is present) | `GH_TOKEN=<token> just gha` reproduces CI (on Windows, `gh auth token` prints one) |
| commit policy: `subject must not start with a capital letter` | Subject starts with a capital letter | Lower-case the first word: `feat(policy): add …` |
