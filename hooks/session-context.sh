#!/usr/bin/env bash
# SessionStart hook: inject a short repo snapshot — current branch, how far
# behind freshly-fetched origin/<default>, and dirty-file count — so the
# fresh-base signal ship-issue checks in Phase 0 is already in context.
# Not a git repo, no origin, offline, or any error: exit 0 with no output.
# The fetch is capped at ~5s; on timeout we fall back to cached remote refs
# and say so rather than hang session startup.
set -u

cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch=$(git -C "$cwd" symbolic-ref --short -q HEAD) \
  || branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null) \
  || branch='?'

behind="no origin remote"
if git -C "$cwd" remote get-url origin >/dev/null 2>&1; then
  default=$(git -C "$cwd" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  [ -n "$default" ] || default=main

  freshness=""
  git -C "$cwd" fetch --quiet --no-tags origin "$default" >/dev/null 2>&1 &
  fpid=$!
  i=0
  while kill -0 "$fpid" 2>/dev/null && [ "$i" -lt 10 ]; do sleep 0.5; i=$((i + 1)); done
  if kill -0 "$fpid" 2>/dev/null; then
    kill "$fpid" 2>/dev/null || true
    freshness=" (fetch timed out — count may be stale)"
  fi
  wait "$fpid" 2>/dev/null || true

  if git -C "$cwd" rev-parse --verify -q "origin/$default" >/dev/null 2>&1; then
    n=$(git -C "$cwd" rev-list --count "HEAD..origin/$default" 2>/dev/null) || n='?'
    behind="$n commit(s) behind origin/$default$freshness"
  else
    behind="origin/$default not found locally"
  fi
fi

dirty=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
echo "[repo-snapshot] branch: $branch; $behind; dirty files: $dirty"
exit 0
