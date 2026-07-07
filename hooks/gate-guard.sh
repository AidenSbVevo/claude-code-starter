#!/usr/bin/env bash
# PreToolUse hook (Bash): the SHIP GATE, enforced in architecture. Exit 2 on
# `gh pr create` / `git push` while the current branch carries an active
# ship-issue plan (.plans/<issue-id>.md, issue-id = branch basename) whose
# approval marker (.plans/<issue-id>.approved) is missing — Claude writes
# that marker only after the user's explicit SHIP GATE approval, so the gate
# can't be walked past as a banner. Every other path — non-publish commands,
# no repo, detached HEAD, no plan file, marker present, any internal error —
# allows (exit 0): outside an active ship-issue run this hook never fires.
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

# Gate 1: only fire on commands that publish — gh pr create or git push.
is_publish=0
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)' && is_publish=1
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+(-[Cc][[:space:]]*[^[:space:]]+[[:space:]]+)*push([[:space:]]|$)' && is_publish=1
[ "$is_publish" = 1 ] || exit 0

# Resolve the repo the command targets: `git -C <dir>` wins, else project dir.
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
cdir=$(printf '%s' "$cmd" | sed -nE 's/.*(^|[;&|[:space:]])git[[:space:]]+-C[[:space:]]*([^[:space:]]+).*/\2/p' | head -1) || cdir=""
if [ -n "$cdir" ]; then
  cdir=${cdir#\"}; cdir=${cdir%\"}; cdir=${cdir#\'}; cdir=${cdir%\'}
  case "$cdir" in
    /*) cwd="$cdir" ;;
    *) cwd="$cwd/$cdir" ;;
  esac
fi
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Detached HEAD (rebase, bisect) → not a ship-issue branch → allow.
branch=$(git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null) || exit 0
[ -n "$branch" ] || exit 0
issue=$(basename "$branch" 2>/dev/null) || exit 0
[ -n "$issue" ] || exit 0

root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

if [ -f "$root/.plans/$issue.md" ] && [ ! -f "$root/.plans/$issue.approved" ]; then
  echo "BLOCKED by SHIP GATE: .plans/$issue.approved not found. This branch has an active ship-issue plan; get the user's explicit SHIP GATE approval, then: touch .plans/$issue.approved and retry." >&2
  exit 2
fi
exit 0
