#!/usr/bin/env bash
# Stop hook: one-shot reminder that ship-issue's Phase 13 retro is mandatory.
# If the current branch's issue (branch basename) has been SHIP-GATE-approved
# (.plans/<issue-id>.approved exists) but .review/journal.md has no
# "RETRO <issue-id>" line yet, block the stop once — exit 2 feeds the
# reminder to Claude — and drop .review/.retro-nag-<issue-id> so it never
# fires again for this issue (Stop exit 2 loops otherwise). Every other
# path — no repo, detached HEAD, no approval marker, retro recorded, marker
# already dropped, any internal error — exits 0. No network, fast by design.
set -u

cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch=$(git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null) || exit 0
[ -n "$branch" ] || exit 0
issue=$(basename "$branch" 2>/dev/null) || exit 0
[ -n "$issue" ] || exit 0

root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

# Only nag after the SHIP GATE — an unapproved plan isn't retro-ready yet.
[ -f "$root/.plans/$issue.approved" ] || exit 0

# Retro already recorded → done.
grep -qF "RETRO $issue" "$root/.review/journal.md" 2>/dev/null && exit 0

# Already nagged once for this issue → stay quiet forever.
nag="$root/.review/.retro-nag-$issue"
[ -f "$nag" ] && exit 0
mkdir -p "$root/.review" 2>/dev/null || exit 0
: > "$nag" 2>/dev/null || exit 0

echo "Ship-issue Phase 13 retro not recorded for $issue — run the retro (promote/demote/calibrate) and append the RETRO line to .review/journal.md, or say why it's skipped. (This reminder fires once.)" >&2
exit 2
