"""
AI-powered issue triage via GitHub Models.

Reads issue context from env vars, asks the model to suggest labels
and a triage comment, then applies both via the GitHub API.

Rate limits: GitHub Models free tier — runs only on issues.opened,
so frequency is naturally bounded by issue creation rate.

Required env vars:
  GITHUB_TOKEN  — built-in token from workflow (issues: write, models: read)
  REPO          — repository in owner/repo format
  ISSUE_NUMBER  — GitHub issue number
  ISSUE_TITLE   — issue title (optional)
  ISSUE_BODY    — issue body (optional)
"""

from __future__ import annotations

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from github_models import REVIEW_MODEL, chat, github_api

SYSTEM_PROMPT = """You are an expert infrastructure engineer triaging GitHub issues
for an IaC repository that uses OpenTofu, GitHub Actions, GitHub Models API, and HCP Terraform.

You must respond with ONLY valid JSON — no markdown, no prose, no code fences.

Available labels (use exact names):
  type:     bug, enhancement, documentation, security, question
  domain:   terraform, github-actions, ai, secrets-management, dependencies
  status:   needs-triage, needs-info
  priority: priority:high, priority:medium, priority:low

Rules:
- Pick 1 type label, 0-2 domain labels, 1 status label, 1 priority label
- If the issue is unclear or missing info, use needs-info instead of needs-triage
- Security issues always get priority:high
- Respond in the same language as the issue (French or English)

JSON schema:
{
  "labels": ["label1", "label2"],
  "comment": "brief triage comment acknowledging the issue and summarising next steps"
}"""


def main() -> None:
    repo = os.environ["REPO"]
    issue_number = int(os.environ["ISSUE_NUMBER"])
    title = os.environ.get("ISSUE_TITLE", "")
    body = os.environ.get("ISSUE_BODY", "") or "(no description)"

    user_prompt = f"Issue title: {title}\n\nIssue body:\n{body[:3000]}"

    print(f"Triaging issue #{issue_number}: {title}")
    raw = chat(system=SYSTEM_PROMPT, user=user_prompt, model=REVIEW_MODEL, max_tokens=600)

    try:
        result = json.loads(raw)
    except json.JSONDecodeError:
        print(f"Model returned non-JSON:\n{raw}", file=sys.stderr)
        sys.exit(1)

    labels: list[str] = result.get("labels", [])
    comment: str = result.get("comment", "")

    try:
        if labels:
            github_api(
                f"/repos/{repo}/issues/{issue_number}/labels",
                method="POST",
                body={"labels": labels},
            )
            print(f"Applied labels: {labels}")

        if comment:
            github_api(
                f"/repos/{repo}/issues/{issue_number}/comments",
                method="POST",
                body={"body": comment},
            )
            print("Posted triage comment.")

    except RuntimeError as exc:
        print(f"GitHub API error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
