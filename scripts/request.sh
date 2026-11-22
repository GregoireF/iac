#!/usr/bin/env bash
# Turn a validated self-service issue into a signed commit and a pull request (`just request <n>`).
# The issue was checked by .github/workflows/requests.yml (label request:ready); it is checked again here
# with the same scripts/request.py, on a fresh branch from origin/main. Commits are signed by the local
# git configuration (the distribution's own key, ansible/roles/workstation/tasks/git.yml).
set -euo pipefail

n="${1:?usage: just request <issue-number>}"
[[ "$n" =~ ^[0-9]+$ ]] || { echo "issue number expected, got '$n'" >&2; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
die() { echo "✗ $*" >&2; exit 1; }

command -v gh >/dev/null || die "gh is required (just workstation installs it), then: gh auth login"
[ -z "$(git status --porcelain)" ] || die "the working tree is not clean"
[ "$(git config --get commit.gpgsign || true)" = true ] || die "commit signing is off (git config commit.gpgsign true)"

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
owner="${repo%%/*}"
issue="$(gh issue view "$n" -R "$repo" --json body,labels,state,author,title)"
[ "$(jq -r .state <<<"$issue")" = OPEN ] || die "issue #$n is not open"
[ "$(jq -r .author.login <<<"$issue")" = "$owner" ] || die "issue #$n was not opened by $owner"
labels="$(jq -r '[.labels[].name] | join(" ")' <<<"$issue")"
[[ " $labels " == *" request:ready "* ]] || die "issue #$n is not labelled request:ready (see the bot comment)"
kind=""
for l in $labels; do case "$l" in request:repository|request:app|request:archive|request:release) kind="${l#request:}" ;; esac; done
[ -n "$kind" ] || die "issue #$n has no request:<kind> label"

body="$(mktemp)"; trap 'rm -f "$body"' EXIT
jq -r .body <<<"$issue" > "$body"

git fetch --quiet origin main
start="$(git rev-parse --abbrev-ref HEAD)"
git switch --quiet -c "request/$n" origin/main
restore() { git switch --quiet "$start"; git branch --quiet -D "request/$n" 2>/dev/null || true; }

if ! plan="$(python3 scripts/request.py apply --kind "$kind" --body-file "$body")"; then
  restore; echo "$plan" | jq -r '.errors[] | "✗ " + .' >&2; exit 1
fi

if [ "$(jq -r .action <<<"$plan")" = release ]; then
  bump="$(jq -r .bump <<<"$plan")"
  since="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "→ release.yml (bump: $bump)"
  gh workflow run release.yml -R "$repo" --ref main -f bump="$bump"
  run=""
  for _ in $(seq 30); do
    run="$(gh run list -R "$repo" --workflow release.yml --limit 5 --json databaseId,createdAt \
           --jq "[.[] | select(.createdAt >= \"$since\")][0].databaseId // empty")"
    [ -n "$run" ] && break; sleep 2
  done
  [ -n "$run" ] || { restore; die "release run not found"; }
  gh run watch "$run" -R "$repo" --exit-status > /dev/null || { restore; die "release run $run failed"; }
  tag="$(gh release view -R "$repo" --json tagName -q .tagName)"
  echo "→ released $tag"
  plan="$(python3 scripts/request.py bump-module-ref --tag "$tag")"
fi

branch="$(jq -r .branch <<<"$plan")"
title="$(jq -r .title <<<"$plan")"
git branch --quiet -m "$branch"
git add -A
msg="$(mktemp)"
{
  echo "$title"
  echo
  echo "Requested in #$n through the self-service form."
  jq -r '.fields | to_entries[] | select(.value != "") | "- \(.key): \(.value)"' <<<"$plan"
} > "$msg"
git commit --quiet -s -F "$msg"; rm -f "$msg"
echo "→ $(git log -1 --format='%h %s')"

git push --quiet -u origin "$branch"
note="$(jq -r '.note // empty' <<<"$plan")"
pr_body="Closes #$n.

$(jq -r '.fields | to_entries[] | select(.value != "") | "- **\(.key)**: \(.value)"' <<<"$plan")
${note:+
> $note}

Read the plan posted below before merging; add the \`run:plan\` label to run it again."
url="$(gh pr create -R "$repo" --base main --head "$branch" --title "$title" --body "$pr_body")"
gh issue comment "$n" -R "$repo" --body "Pull request: $url" > /dev/null
echo "✓ $url"
