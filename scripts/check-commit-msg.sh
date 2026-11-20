#!/usr/bin/env bash
# Commit message policy (docs/adr/0002-solo-flow.md): one human author per commit.
#   - no co-author / generated-by / assisted-by trailer, no "Generated with [tool](link)" footer
#   - Developer Certificate of Origin: a "Signed-off-by:" trailer is required (git commit -s);
#     with --author, it must be that author's own sign-off
# Usage: check-commit-msg.sh [--trailers-only] [--author "Name <email>"] <commit-message-file>
#   commit-msg hook (pre-commit passes the file), `just commits`, commit-policy.yml.
#   --trailers-only: trailer/footer rule only (bot commits, which cannot sign off).
set -euo pipefail

trailers_only=0
author=""
while [ $# -gt 1 ]; do
  case "$1" in
    --trailers-only) trailers_only=1; shift ;;
    --author) author="$2"; shift 2 ;;
    *) break ;;
  esac
done
msg_file="${1:?usage: check-commit-msg.sh [--trailers-only] [--author \"Name <email>\"] <commit-message-file>}"
msg="$(grep -v '^#' "$msg_file" || true)"

forbidden='^(co-authored-by|generated-by|assisted-by):|^.{0,8}generated with \[[^]]+\]\(https?://'
if grep -qiE "$forbidden" <<<"$msg"; then
  echo "commit-msg: co-author or generated-by attribution found — this repository has a single human author." >&2
  grep -iE "$forbidden" <<<"$msg" >&2
  exit 1
fi

[ "$trailers_only" -eq 1 ] && exit 0

if ! grep -qE '^Signed-off-by: .+ <.+>$' <<<"$msg"; then
  echo "commit-msg: missing 'Signed-off-by:' trailer — commit with: git commit -s" >&2
  exit 1
fi

if [ -n "$author" ] && ! grep -qxF "Signed-off-by: $author" <<<"$msg"; then
  echo "commit-msg: the sign-off must be the author's own (expected 'Signed-off-by: $author')." >&2
  exit 1
fi
