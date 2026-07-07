#!/usr/bin/env bash
# SessionStart hook: inject a short repo snapshot — current branch, how far
# behind origin/<default>, and dirty-file count — so the fresh-base signal
# ship-issue checks in Phase 0 is already in context. Network calls (fetch,
# ls-remote) run only on a fresh startup (.source == "startup"); resume/
# clear/compact print the same snapshot from cached refs and say so — no
# network tax on every /clear. Also installs .plans/ + .review/ into
# .git/info/exclude: SessionStart runs unconditionally, so the scratch dirs
# are excluded before any git add can stage them (scratch-guard's lazy
# install only fired on git add). Not a git repo, no origin, offline, or any
# error: exit 0 with no output. Network is capped ~5s via timeout/gtimeout
# when available (background + poll fallback otherwise); on timeout we fall
# back to cached refs and say so rather than hang session startup.
set -u

payload=$(cat 2>/dev/null || true)
src=""
if [ -n "$payload" ]; then
  if command -v jq >/dev/null 2>&1; then
    src=$(printf '%s' "$payload" | jq -r '.source // empty' 2>/dev/null) || src=""
  elif command -v python3 >/dev/null 2>&1; then
    src=$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("source",""))' 2>/dev/null) || src=""
  fi
fi

cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Keep the scratch dirs untrackable in this repo, idempotently.
gitdir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null) || gitdir=""
if [ -n "$gitdir" ]; then
  case "$gitdir" in /*) : ;; *) gitdir="$cwd/$gitdir" ;; esac
  excl="$gitdir/info/exclude"
  mkdir -p "$gitdir/info" 2>/dev/null || true
  for d in '.plans/' '.review/'; do
    grep -qxF "$d" "$excl" 2>/dev/null || printf '%s\n' "$d" >> "$excl" 2>/dev/null || true
  done
fi

# Cap a command at $1 seconds: timeout/gtimeout when present (clean kill),
# else background + poll (best effort — a killed fetch may orphan children).
TIMEOUT_BIN=""
command -v timeout >/dev/null 2>&1 && TIMEOUT_BIN="timeout"
[ -n "$TIMEOUT_BIN" ] || { command -v gtimeout >/dev/null 2>&1 && TIMEOUT_BIN="gtimeout"; }
run_capped() {
  secs="$1"; shift
  if [ -n "$TIMEOUT_BIN" ]; then
    "$TIMEOUT_BIN" "$secs" "$@" 2>/dev/null
    return $?
  fi
  "$@" 2>/dev/null &
  rc_pid=$!
  i=0
  max=$((secs * 2))
  while kill -0 "$rc_pid" 2>/dev/null && [ "$i" -lt "$max" ]; do sleep 0.5; i=$((i + 1)); done
  if kill -0 "$rc_pid" 2>/dev/null; then
    kill "$rc_pid" 2>/dev/null || true
    wait "$rc_pid" 2>/dev/null
    return 124
  fi
  wait "$rc_pid"
}

branch=$(git -C "$cwd" symbolic-ref --short -q HEAD) \
  || branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null) \
  || branch='?'

behind="no origin remote"
if git -C "$cwd" remote get-url origin >/dev/null 2>&1; then
  default=$(git -C "$cwd" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  if [ -z "$default" ] && [ "$src" = "startup" ]; then
    # origin/HEAD unset locally — ask the remote once before assuming main.
    default=$(run_capped 5 git -C "$cwd" ls-remote --symref origin HEAD \
      | awk '$1 == "ref:" { sub("^refs/heads/", "", $2); print $2; exit }') || default=""
  fi
  [ -n "$default" ] || default=main

  freshness=""
  if [ "$src" = "startup" ]; then
    run_capped 5 git -C "$cwd" fetch --quiet --no-tags origin "$default" >/dev/null 2>&1 \
      || freshness=" (fetch failed or timed out — count may be stale)"
  else
    freshness=" (cached refs — no fetch on ${src:-non-startup} session)"
  fi

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
