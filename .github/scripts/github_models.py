"""
Shared client for the GitHub Models API.
Compatible with the OpenAI chat completions format.
Uses stdlib only — no pip required.
"""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from typing import Any

_API_URL = "https://models.inference.ai.azure.com/chat/completions"

# Model selection guide:
#   gpt-4o-mini  → fast, cheap  — triage, summarisation
#   gpt-4o       → best quality — code review, complex reasoning
DEFAULT_MODEL = "gpt-4o-mini"
REVIEW_MODEL = "gpt-4o"


def chat(
    *,
    system: str,
    user: str,
    model: str = DEFAULT_MODEL,
    temperature: float = 0.2,
    max_tokens: int = 1500,
) -> str:
    token = os.environ["GITHUB_TOKEN"]
    payload = json.dumps(
        {
            "model": model,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
    ).encode()

    req = urllib.request.Request(
        _API_URL,
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data: dict[str, Any] = json.loads(resp.read())
            return data["choices"][0]["message"]["content"].strip()
    except urllib.error.HTTPError as exc:
        body = exc.read().decode(errors="replace")
        raise RuntimeError(f"GitHub Models API {exc.code}: {body}") from exc


def github_api(
    path: str,
    *,
    method: str = "GET",
    body: dict[str, Any] | None = None,
) -> Any:
    token = os.environ["GITHUB_TOKEN"]
    url = f"https://api.github.com{path}"
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read()) if resp.length != 0 else {}
    except urllib.error.HTTPError as exc:
        body_text = exc.read().decode(errors="replace")
        raise RuntimeError(f"GitHub API {method} {path} → HTTP {exc.code}: {body_text}") from exc
