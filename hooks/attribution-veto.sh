#!/usr/bin/env bash
# PreToolUse hook (Bash): deterministic enforcement of the no-AI-attribution
# rule. THE ONE HOOK THAT BLOCKS: exit 2 when a command that creates a commit
# or PR (git commit / gh pr create) carries an attribution marker. Everything
# else — non-commit commands, greps that merely mention the markers, and all
# internal error paths — allows (exit 0).
set -u

payload=$(cat 2>/dev/null || true)
[ -n "$payload" ] || exit 0

cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null) || cmd=""
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null) || cmd=""
fi
# Fallback: scan the raw payload — the commit-command gate below still applies.
[ -n "$cmd" ] || cmd="$payload"

# Gate 1: only fire on commands that actually create a commit or a PR.
is_commit=0
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+[[:space:]]+|-c[[:space:]]+[^[:space:]]+[[:space:]]+)*commit([[:space:]]|$)' && is_commit=1
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+(create|edit)([[:space:]]|$)' && is_commit=1
[ "$is_commit" = 1 ] || exit 0

# Gate 2: attribution markers (byte-wise case glob — locale-safe for the emoji).
lower=$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')
case "$lower" in
  *co-authored-by*|*"generated with"*|*noreply@anthropic.com*|*🤖*)
    echo "BLOCKED: this commit/PR text contains AI attribution (Co-Authored-By / 'Generated with' / 🤖 / anthropic no-reply). Strip the attribution and retry — no-attribution is a standing rule (see ~/.claude/CLAUDE.md)." >&2
    exit 2
    ;;
esac
exit 0
