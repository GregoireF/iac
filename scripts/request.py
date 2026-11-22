#!/usr/bin/env python3
"""Self-service requests (IssueOps) — parse, validate and apply an issue form.

Shared by .github/workflows/requests.yml (validation + preview comment) and `just request <n>`
(local change, signed commit, pull request). Standard library only.

  request.py check --kind KIND --body-file FILE    validate; print JSON fields, or errors (exit 1)
  request.py apply --kind KIND --body-file FILE    change the working tree; print a JSON plan
  request.py bump-module-ref --tag vX.Y.Z           move ?ref= of the module in terraform/github

KIND is the suffix of the issue label: repository | app | archive | release.
The issue body is untrusted input: every value is validated before it reaches a file.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOCALS = ROOT / "terraform/github/locals.tf"
REPOS_TF = ROOT / "terraform/github/repos.tf"
APPS = ROOT / "kubernetes/apps"

# Issue form field labels (must match .github/ISSUE_TEMPLATE/request-*.yml) -> keys
FORMS: dict[str, dict[str, str]] = {
    "repository": {
        "Repository name": "name",
        "Description": "description",
        "Visibility": "visibility",
        "Topics": "topics",
        "Branch protection": "protection",
    },
    "app": {
        "Application name": "name",
        "Chart (OCI URL)": "chart",
        "Chart version": "version",
        "Updates source": "updates",
    },
    "archive": {"Repository name": "name", "Reason": "reason"},
    "release": {"Bump": "bump", "Why": "why"},
}

REPO_NAME = re.compile(r"^[A-Za-z0-9._-]{1,100}$")
TOPIC = re.compile(r"^[a-z0-9][a-z0-9-]{0,49}$")
DNS_LABEL = re.compile(r"^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$")
OCI_URL = re.compile(r"^oci://[a-z0-9.-]+(:[0-9]{1,5})?(/[a-z0-9._-]+)+$")
VERSION = re.compile(r"^v?[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$")
GH_REPO = re.compile(r"^[A-Za-z0-9-]{1,39}/[A-Za-z0-9._-]{1,100}$")
TAG = re.compile(r"^v[0-9]+\.[0-9]+\.[0-9]+$")


class RequestError(Exception):
    def __init__(self, errors: list[str]):
        super().__init__("\n".join(errors))
        self.errors = errors


# --------------------------------------------------------------------------- parsing
def parse(kind: str, body: str) -> dict[str, str]:
    """GitHub renders issue forms as '### <label>' followed by the answer."""
    if kind not in FORMS:
        raise RequestError([f"unknown request kind '{kind}'"])
    sections: dict[str, str] = {}
    current = None
    for line in body.replace("\r\n", "\n").split("\n"):
        heading = re.match(r"^###\s+(.+?)\s*$", line)
        if heading:
            current = heading.group(1)
            sections[current] = ""
        elif current is not None:
            sections[current] += line + "\n"
    fields = {}
    for label, key in FORMS[kind].items():
        value = sections.get(label, "").strip()
        fields[key] = "" if value == "_No response_" else value
    return fields


def hcl_string(value: str) -> str:
    """Quote a value for HCL: escape backslashes, quotes and interpolation markers."""
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("${", "$${").replace("%{", "%%{")
    return f'"{escaped}"'


def existing_repositories(text: str) -> set[str]:
    block = repositories_block(text)
    names = set()
    depth = 0
    for line in text[block[0]:block[1]].split("\n"):
        m = re.match(r'^\s*"?([A-Za-z0-9._-]+)"?\s*=\s*\{\s*$', line)
        if m and depth == 1:
            names.add(m.group(1))
        depth += brace_delta(line)
    return names


def brace_delta(line: str) -> int:
    """Net { } count of one HCL line, ignoring braces inside strings and comments."""
    delta, in_str, i = 0, False, 0
    while i < len(line):
        c = line[i]
        if in_str:
            if c == "\\":
                i += 1
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c == "#" or line.startswith("//", i):
            break
        elif c == "{":
            delta += 1
        elif c == "}":
            delta -= 1
        i += 1
    return delta


def repositories_block(text: str) -> tuple[int, int]:
    """(start, end) offsets of the body of `repositories = { ... }`; end = offset of its closing line."""
    m = re.search(r"^(\s*)repositories\s*=\s*\{\s*$", text, re.M)
    if not m:
        raise RequestError(["`repositories = {` not found in terraform/github/locals.tf"])
    pos, depth = m.start(), 0
    for line in text[m.start():].split("\n"):
        depth += brace_delta(line)
        if depth == 0:
            return m.start(), pos
        pos += len(line) + 1
    raise RequestError(["unbalanced braces in terraform/github/locals.tf"])


# --------------------------------------------------------------------------- validation
def validate(kind: str, f: dict[str, str]) -> list[str]:
    errors: list[str] = []
    if kind in ("repository", "archive"):
        repos = existing_repositories(LOCALS.read_text(encoding="utf-8"))
        if not REPO_NAME.match(f["name"]):
            errors.append("Repository name: letters, digits, '.', '_' or '-', at most 100 characters.")
        elif kind == "repository" and f["name"] in repos:
            errors.append(f"Repository name: `{f['name']}` is already managed.")
        elif kind == "archive" and f["name"] not in repos:
            errors.append(f"Repository name: `{f['name']}` is not managed by terraform/github.")
    if kind == "repository":
        if not 1 <= len(f["description"]) <= 350 or "\n" in f["description"]:
            errors.append("Description: one line, 1 to 350 characters.")
        if f["visibility"] not in ("public", "private"):
            errors.append("Visibility: public or private.")
        topics = [t.strip() for t in f["topics"].split(",") if t.strip()]
        bad = [t for t in topics if not TOPIC.match(t)]
        if bad or len(topics) > 20:
            errors.append("Topics: up to 20, lower case, digits and '-' (invalid: " + ", ".join(bad or ["too many"]) + ").")
        if f["protection"] not in ("yes", "no"):
            errors.append("Branch protection: yes or no.")
    if kind == "app":
        if not DNS_LABEL.match(f["name"]):
            errors.append("Application name: a DNS label (lower case, digits, '-', at most 63).")
        elif (APPS / "base" / f["name"]).exists():
            errors.append(f"Application name: kubernetes/apps/base/{f['name']} already exists.")
        if not OCI_URL.match(f["chart"]):
            errors.append("Chart (OCI URL): e.g. oci://ghcr.io/stefanprodan/charts/podinfo.")
        if not VERSION.match(f["version"]):
            errors.append("Chart version: a semantic version such as 6.17.0.")
        if f["updates"] and not GH_REPO.match(f["updates"]):
            errors.append("Updates source: owner/repository on GitHub, or empty.")
    if kind == "release" and f["bump"] not in ("patch", "minor", "major"):
        errors.append("Bump: patch, minor or major.")
    return errors


# --------------------------------------------------------------------------- apply
def apply_repository(f: dict[str, str]) -> dict:
    text = LOCALS.read_text(encoding="utf-8")
    _, end = repositories_block(text)
    topics = ", ".join(hcl_string(t.strip()) for t in f["topics"].split(",") if t.strip())
    protected = "true" if f["protection"] == "yes" else "false"
    # A bare HCL identifier starts with a letter or '_'; anything else (e.g. ".github") is quoted
    key = f["name"] if re.match(r"^[A-Za-z_][A-Za-z0-9_-]*$", f["name"]) else hcl_string(f["name"])
    entry = f"""
    {key} = {{
      description            = {hcl_string(f['description'])}
      topics                 = [{topics}]
      visibility             = {hcl_string(f['visibility'])}
      has_issues             = true
      has_wiki               = false
      has_projects           = false
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      archived               = false
      allow_auto_merge       = true
      inject_standard_files  = true

      branch_protection = {{
        enabled                      = {protected}
        required_status_checks       = []
        enforce_conventional_commits = true
      }}
    }}
"""
    LOCALS.write_text(text[:end].rstrip("\n") + "\n" + entry + text[end:], encoding="utf-8")
    return {
        "branch": f"request/repository-{f['name'].lower()}",
        "title": f"feat(github): add the {f['name']} repository",
        "files": [str(LOCALS.relative_to(ROOT))],
    }


def apply_archive(f: dict[str, str]) -> dict:
    lines = LOCALS.read_text(encoding="utf-8").split("\n")
    start = next(i for i, l in enumerate(lines) if re.match(rf'^\s{{4}}"?{re.escape(f["name"])}"?\s*=\s*\{{\s*$', l))
    depth, changed = 0, False
    for i in range(start, len(lines)):
        if depth == 1 and re.match(r"^\s*archived\s*=\s*false\s*$", lines[i]):
            lines[i] = lines[i].replace("false", "true")
            changed = True
            break
        depth += brace_delta(lines[i])
        if depth == 0 and i > start:
            break
    if not changed:
        raise RequestError([f"`archived = false` not found in the `{f['name']}` block (already archived?)."])
    LOCALS.write_text("\n".join(lines), encoding="utf-8")
    return {
        "branch": f"request/archive-{f['name'].lower()}",
        "title": f"feat(github): archive the {f['name']} repository",
        "files": [str(LOCALS.relative_to(ROOT))],
    }


def apply_app(f: dict[str, str]) -> dict:
    name, base = f["name"], APPS / "base" / f["name"]
    base.mkdir(parents=True)
    if f["updates"]:
        renovate = f"# renovate: datasource=github-releases depName={f['updates']}"
    else:
        renovate = f"# renovate: datasource=docker depName={f['chart'].removeprefix('oci://')}"
    (base / "ocirepository.yaml").write_text(f"""# {name}: requested through the self-service form, installed from its OCI Helm chart.
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: {name}
  namespace: apps
spec:
  interval: 1h
  url: {f['chart']}
  ref:
    {renovate}
    tag: {f['version']}
  layerSelector:
    mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
    operation: copy
""", encoding="utf-8")
    (base / "helmrelease.yaml").write_text(f"""apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: {name}
  namespace: apps
spec:
  interval: 30m
  chartRef:
    kind: OCIRepository
    name: {name}
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: 3
  # Chart-specific values. Namespace "apps" enforces the "restricted" Pod Security Standard:
  # set a non-root, read-only, no-privilege-escalation security context and resource limits
  # (see kubernetes/apps/base/podinfo/helmrelease.yaml).
  values: {{}}
""", encoding="utf-8")
    (base / "kustomization.yaml").write_text(
        "apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n  - ocirepository.yaml\n  - helmrelease.yaml\n",
        encoding="utf-8")
    overlay = APPS / "local" / "kustomization.yaml"
    text = overlay.read_text(encoding="utf-8")
    overlay.write_text(text.rstrip("\n") + f"\n  - ../base/{name}\n", encoding="utf-8")
    return {
        "branch": f"request/app-{name}",
        "title": f"feat(kubernetes): add the {name} application",
        "files": [str(p.relative_to(ROOT)) for p in sorted(base.iterdir())] + [str(overlay.relative_to(ROOT))],
        "note": "Set the chart values for the restricted Pod Security Standard before merging; `just up` proves it.",
    }


def bump_module_ref(tag: str) -> dict:
    if not TAG.match(tag):
        raise RequestError([f"invalid tag '{tag}'"])
    text = REPOS_TF.read_text(encoding="utf-8")
    new, n = re.subn(r"(modules/github/repository\?ref=)v[0-9]+\.[0-9]+\.[0-9]+", rf"\g<1>{tag}", text)
    if n == 0:
        raise RequestError(["no `modules/github/repository?ref=` source found in terraform/github/repos.tf"])
    REPOS_TF.write_text(new, encoding="utf-8")
    return {
        "branch": f"request/module-{tag}",
        "title": f"chore(github): use the repository module {tag}",
        "files": [str(REPOS_TF.relative_to(ROOT))],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for cmd in ("check", "apply"):
        p = sub.add_parser(cmd)
        p.add_argument("--kind", required=True, choices=sorted(FORMS))
        p.add_argument("--body-file", required=True, type=Path)
    p = sub.add_parser("bump-module-ref")
    p.add_argument("--tag", required=True)
    args = ap.parse_args()
    try:
        if args.cmd == "bump-module-ref":
            print(json.dumps(bump_module_ref(args.tag)))
            return 0
        fields = parse(args.kind, args.body_file.read_text(encoding="utf-8"))
        errors = validate(args.kind, fields)
        if errors:
            raise RequestError(errors)
        if args.cmd == "check":
            print(json.dumps({"kind": args.kind, "fields": fields}))
            return 0
        if args.kind == "release":
            plan = {"action": "release", "bump": fields["bump"]}
        else:
            plan = {"repository": apply_repository, "archive": apply_archive, "app": apply_app}[args.kind](fields)
            plan["action"] = "commit"
        plan["fields"] = fields
        print(json.dumps(plan))
        return 0
    except RequestError as e:
        print(json.dumps({"errors": e.errors}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
