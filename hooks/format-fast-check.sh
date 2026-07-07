#!/usr/bin/env bash
# PostToolUse hook (Edit|MultiEdit|Write): format the edited file with the
# repo's OWN formatter (never impose one the repo doesn't configure), then run
# a fast lint check on that file only. Real lint findings on the edited file
# exit 2 so the model sees them (PostToolUse stderr only reaches Claude on
# exit 2; the edit already landed — nothing is undone). Tool-failure paths —
# missing tool, payload parse error, formatter or linter crash — exit 0 so a
# broken hook never blocks an edit. Slow suites (pytest, tsc, eslint)
# deliberately do not run here; they belong in the dev pipeline, not on every
# keystroke.
set -u

payload=$(cat 2>/dev/null || true)
[ -n "$payload" ] || exit 0

file=""
if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || file=""
elif command -v python3 >/dev/null 2>&1; then
  file=$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null) || file=""
fi
[ -n "$file" ] && [ -f "$file" ] || exit 0

dir=$(dirname "$file")
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root="$dir"

# Prefer the repo's own copy of a tool (.venv, node_modules) over PATH.
find_tool() {
  if [ -x "$root/.venv/bin/$1" ]; then printf '%s' "$root/.venv/bin/$1"; return 0; fi
  if [ -x "$root/node_modules/.bin/$1" ]; then printf '%s' "$root/node_modules/.bin/$1"; return 0; fi
  command -v "$1" 2>/dev/null
}

warn() { printf '[format-hook] %s\n' "$*" >&2; }

case "$file" in
  *.py)
    uses_ruff=0; uses_black=0
    { [ -f "$root/ruff.toml" ] || [ -f "$root/.ruff.toml" ] || grep -qs 'tool\.ruff' "$root/pyproject.toml"; } && uses_ruff=1
    grep -qs 'tool\.black' "$root/pyproject.toml" && uses_black=1
    [ -x "$root/.venv/bin/ruff" ] && uses_ruff=1
    if [ "$uses_ruff" = 1 ]; then
      ruff=$(find_tool ruff) || exit 0
      "$ruff" format --quiet "$file" >/dev/null 2>&1 || warn "ruff format failed on ${file##*/}"
      out=$("$ruff" check --quiet "$file" 2>&1)
      rc=$?
      if [ "$rc" -eq 1 ] && [ -n "$out" ]; then
        # rc 1 = real findings — surface them to the model (exit 2).
        printf '[format-hook] ruff findings on %s — fix before moving on:\n%s\n' \
          "${file##*/}" "$(printf '%s' "$out" | head -40)" >&2
        exit 2
      elif [ "$rc" -ne 0 ]; then
        # rc 2+ = ruff itself failed (bad config, crash) — warn, never block.
        warn "ruff check errored on ${file##*/}: $(printf '%s' "$out" | head -5)"
      fi
    elif [ "$uses_black" = 1 ]; then
      black=$(find_tool black) || exit 0
      "$black" --quiet "$file" >/dev/null 2>&1 || warn "black failed on ${file##*/}"
    fi
    ;;
  *.js|*.jsx|*.ts|*.tsx|*.css)
    # Only when the repo itself ships prettier — never format with a global one.
    if [ -x "$root/node_modules/.bin/prettier" ]; then
      "$root/node_modules/.bin/prettier" --log-level warn --write "$file" >/dev/null 2>&1 \
        || warn "prettier failed on ${file##*/}"
    fi
    ;;
  *.rs)
    if [ -f "$root/Cargo.toml" ] && command -v rustfmt >/dev/null 2>&1; then
      rustfmt "$file" >/dev/null 2>&1 || warn "rustfmt failed on ${file##*/}"
    fi
    ;;
  *.go)
    if command -v gofmt >/dev/null 2>&1; then
      gofmt -w "$file" >/dev/null 2>&1 || warn "gofmt failed on ${file##*/}"
    fi
    ;;
esac
exit 0
