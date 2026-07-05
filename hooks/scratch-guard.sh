#!/usr/bin/env bash
# PreToolUse hook (Bash): warn — never block — when a git add would stage
# .plans/ or .review/ scratch artifacts, either explicitly or via a blind
# `git add -A` / `git add .` while those dirs have changes. Exit 1 is the
# non-blocking "show a warning, let it proceed" path; every other outcome
# (including all errors) is exit 0. Also keeps both dirs in the repo's
# .git/info/exclude, idempotently, so they normally can't be staged at all.
set -u

payload=$(cat 2>/dev/null || true)
[ -n "$payload" ] || exit 0

cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null) || cmd=""
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null) || cmd=""
fi
[ -n "$cmd" ] || exit 0

# Only care about git add commands.
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?add([[:space:]]|$)' || exit 0

cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Best-effort: make sure the scratch dirs are excluded from tracking.
gitdir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null) || gitdir=""
if [ -n "$gitdir" ]; then
  case "$gitdir" in /*) : ;; *) gitdir="$cwd/$gitdir" ;; esac
  excl="$gitdir/info/exclude"
  mkdir -p "$gitdir/info" 2>/dev/null || true
  for d in '.plans/' '.review/'; do
    grep -qxF "$d" "$excl" 2>/dev/null || printf '%s\n' "$d" >> "$excl" 2>/dev/null || true
  done
fi

warnmsg=""
if printf '%s' "$cmd" | grep -qE '\.(plans|review)(/|[[:space:]]|$)'; then
  warnmsg="this git add explicitly touches .plans/ or .review/"
elif printf '%s' "$cmd" | grep -qE 'add[[:space:]]+(-A|--all|-a[[:space:]]|\.([[:space:]]|$|["'\'']))'; then
  if [ -n "$(git -C "$cwd" status --porcelain -- .plans .review 2>/dev/null | head -1)" ]; then
    warnmsg="blind git add (-A / .) while .plans/ or .review/ have changes"
  fi
fi

if [ -n "$warnmsg" ]; then
  echo "[scratch-guard] $warnmsg — scratch dirs are never committed (standing rule). They are in .git/info/exclude; if staged, unstage with: git reset -- .plans .review" >&2
  exit 1
fi
exit 0
