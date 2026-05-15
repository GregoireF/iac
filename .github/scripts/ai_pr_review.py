"""
AI-powered PR review via GitHub Models.

Fetches the diff for changed IaC files and posts a structured review comment.
Focuses on OpenTofu best practices, security, and conventions for this repo.

Skips the review if no relevant files changed (non-IaC changes).
Updates an existing bot comment rather than spamming new ones.

Required env vars:
  GITHUB_TOKEN  — built-in token (contents: read, pull-requests: write, models: read)
  REPO          — repository in owner/repo format
  PR_NUMBER     — pull request number
  BASE_SHA      — base commit SHA
  HEAD_SHA      — head commit SHA
"""

from __future__ import annotations

import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from github_models import REVIEW_MODEL, chat, github_api

SYSTEM_PROMPT = """You are a senior infrastructure engineer reviewing OpenTofu/Terraform code.
This repo manages GitHub resources (repos, rulesets, labels, files) via the integrations/github provider.

Review the provided diff and respond in markdown with these sections (omit sections with no findings):

## Security
- Sensitive values not marked `sensitive = true`
- Potential secret exposure
- Overly permissive rulesets or missing `prevent_destroy`

## Best practices
- Naming conventions (snake_case keys, descriptive names)
- `for_each` vs `count` usage
- `lifecycle` blocks where needed
- Missing `required_version` or provider version pins

## Correctness
- Logic errors, wrong resource types, broken references
- Import blocks that may conflict with existing state

## Suggestions
- Optional improvements to DX or maintainability

If the diff looks clean, say so briefly. Be direct. No filler.
Respond in the same language as the PR title if French, otherwise English."""


REVIEWED_EXTENSIONS = {".tf", ".yml", ".yaml", ".py", ".json", ".md"}
BOT_MARKER = "<!-- ai-pr-review -->"


def get_diff() -> str:
    base = os.environ["BASE_SHA"]
    head = os.environ["HEAD_SHA"]
    try:
        result = subprocess.run(
            ["git", "diff", base, head, "--", "terraform/", "modules/", ".github/"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout
    except subprocess.CalledProcessError as exc:
        print(f"git diff failed (exit {exc.returncode}): {exc.stderr}", file=sys.stderr)
        sys.exit(1)


def main() -> None:
    repo = os.environ["REPO"]
    pr_number = int(os.environ["PR_NUMBER"])

    diff = get_diff()
    if not diff.strip():
        print("No relevant diff found — skipping review.")
        return

    # Truncate to avoid context limits
    if len(diff) > 12000:
        diff = diff[:12000] + "\n\n... (diff truncated)"

    print(f"Reviewing PR #{pr_number} ({len(diff)} chars of diff)")
    review = chat(system=SYSTEM_PROMPT, user=diff, model=REVIEW_MODEL, max_tokens=1200)

    body = f"{BOT_MARKER}\n### AI Review\n\n{review}\n\n---\n*Powered by GitHub Models (`{REVIEW_MODEL}`)*"

    try:
        comments = github_api(f"/repos/{repo}/issues/{pr_number}/comments")
        existing = next(
            (c for c in comments if BOT_MARKER in c.get("body", "")),
            None,
        )

        if existing:
            github_api(
                f"/repos/{repo}/issues/comments/{existing['id']}",
                method="PATCH",
                body={"body": body},
            )
            print("Updated existing review comment.")
        else:
            github_api(
                f"/repos/{repo}/issues/{pr_number}/comments",
                method="POST",
                body={"body": body},
            )
            print("Posted review comment.")

    except RuntimeError as exc:
        print(f"GitHub API error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
