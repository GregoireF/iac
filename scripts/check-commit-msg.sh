#!/usr/bin/env bash
# Commit message policy (docs/adr/0002-solo-flow.md): one human author per commit.
#   - Conventional Commits, the @commitlint/config-conventional rules this repository used:
#     type in the list below, lower-case scope, subject not capitalised and without a final
#     period, header <= 100 characters, body and footer lines <= 200
#   - no co-author / generated-by / assisted-by trailer, no "Generated with [tool](link)" footer
#   - Developer Certificate of Origin: a "Signed-off-by:" trailer is required (git commit -s);
#     with --author, it must be that author's own sign-off
# Usage: check-commit-msg.sh [--trailers-only] [--author "Name <email>"] <commit-message-file>
#   commit-msg hook (pre-commit passes the file), `just commits`, commit-policy.yml.
#   --trailers-only: trailer/footer rule only (bot commits, which cannot sign off).
set -euo pipefail

fail() { echo "commit-msg: $*" >&2; exit 1; }

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

# Conventional Commits. Like commitlint, merge, revert and fixup/squash messages are not checked.
header="$(head -n1 <<<"$msg")"
if ! grep -qE '^(Merge |Revert "|fixup! |squash! )' <<<"$header"; then
  types='build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test'
  [[ "$header" =~ ^($types)(\([a-z0-9][a-z0-9/._-]*\))?!?:\ (.+)$ ]] ||
    fail "header must be '<type>(<scope>): <subject>' with type in: ${types//|/, } — got: $header"
  subject="${BASH_REMATCH[3]}"
  [[ "$subject" =~ ^[A-Z] ]] && fail "subject must not start with a capital letter: $subject"
  [[ "$subject" == *. ]] && fail "subject must not end with a period: $subject"
  [ "${#header}" -le 100 ] || fail "header is ${#header} characters, the limit is 100"
  long="$(tail -n +2 <<<"$msg" | awk 'length > 200 { print NR + 1 ": " length " characters" }')"
  [ -z "$long" ] || fail "body or footer lines longer than 200 characters (line: length): $long"
fi

if ! grep -qE '^Signed-off-by: .+ <.+>$' <<<"$msg"; then
  echo "commit-msg: missing 'Signed-off-by:' trailer — commit with: git commit -s" >&2
  exit 1
fi

if [ -n "$author" ] && ! grep -qxF "Signed-off-by: $author" <<<"$msg"; then
  echo "commit-msg: the sign-off must be the author's own (expected 'Signed-off-by: $author')." >&2
  exit 1
fi
