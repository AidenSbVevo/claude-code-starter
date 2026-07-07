#!/usr/bin/env bash
# PreToolUse hook (Bash): when a git add would stage .plans/ or .review/
# scratch artifacts, either explicitly or via a blind `git add -A` /
# `git add .` while those dirs have changes, emit the PreToolUse JSON "ask"
# decision (exit 0) so the user confirms — the old exit-1 stderr warning was
# invisible to the model. Honors `git -C <dir>` so the repo the add actually
# targets gets both the exclude write and the status check. Every other
# outcome (including all errors) is exit 0 with no output. Also keeps both
# dirs in the repo's .git/info/exclude, idempotently, so they normally can't
# be staged at all (session-context.sh installs the same excludes at
# SessionStart; this is the backstop for repos entered mid-session).
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

# Resolve the repo the add targets: `git -C <dir>` wins, else project dir.
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
  reason="[scratch-guard] $warnmsg — scratch dirs are never committed (standing rule). They are in .git/info/exclude; if staged, unstage with: git reset -- .plans .review"
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}' 2>/dev/null \
      || printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  else
    # $reason is built only from fixed strings above — safe to inline in JSON.
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  fi
fi
exit 0
