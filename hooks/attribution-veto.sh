#!/usr/bin/env bash
# PreToolUse hook (Bash): deterministic enforcement of the no-AI-attribution
# rule. Exit 2 when a command that creates a commit or PR (git commit /
# gh pr create) carries an attribution marker — inline OR inside a message
# file passed via -F/--file/--body-file/-t/--template (ship-issue Phase 11
# mandates --body-file, so the hook reads the file, not just the command
# line). Everything else — non-commit commands, greps that merely mention
# the markers, nonexistent/unreadable message files, and all internal error
# paths — allows (exit 0).
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

# Gate 3: markers hidden in message-file arguments. Normalize --flag=value to
# --flag value, then take the token after each message-file flag. Quoted paths
# with spaces truncate here — the resulting path won't exist and allows, which
# is the correct failure mode for this hook.
files=$(printf '%s' "$cmd" \
  | sed -E 's/--(file|body-file|template)=/--\1 /g' \
  | tr -s '[:space:]' '\n' \
  | awk 'prev == "-F" || prev == "--file" || prev == "--body-file" || prev == "-t" || prev == "--template" { print } { prev = $0 }' 2>/dev/null) || files=""

if [ -n "$files" ]; then
  base="${CLAUDE_PROJECT_DIR:-$PWD}"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    f=${f#\"}; f=${f%\"}; f=${f#\'}; f=${f%\'}
    case "$f" in ''|-*) continue ;; esac
    path="$f"
    if [ ! -f "$path" ]; then
      case "$f" in
        /*) : ;;
        *) path="$base/$f" ;;
      esac
    fi
    [ -f "$path" ] && [ -r "$path" ] || continue
    flower=$(head -c 65536 "$path" 2>/dev/null | tr '[:upper:]' '[:lower:]') || continue
    case "$flower" in
      *co-authored-by*|*"generated with"*|*noreply@anthropic.com*|*🤖*)
        echo "BLOCKED: message file '$f' (passed via -F/--file/--body-file/--template) contains AI attribution (Co-Authored-By / 'Generated with' / 🤖 / anthropic no-reply). Strip the attribution from the file and retry — no-attribution is a standing rule (see ~/.claude/CLAUDE.md)." >&2
        exit 2
        ;;
    esac
  done <<EOF
$files
EOF
fi
exit 0
