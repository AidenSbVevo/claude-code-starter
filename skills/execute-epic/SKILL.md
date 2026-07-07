---
name: execute-epic
description: "Run an epic end-to-end: read its child issues from Linear, pick the next unblocked one in dependency order, drive it through ship-issue, record the disposition, repeat. Use when the user wants to run, execute, continue, or work through an epic, asks for the 'next issue in the epic', or resumes an epic in a fresh session. Not for single issues (ship-issue) or creating issues (epic-planning)."
---

# execute-epic — epic → sequenced ship-issue runs

epic-planning ends at "report the created IDs"; ship-issue intakes one ID.
This skill is the sequencer between them: it owns issue *order* and epic
*state*, and delegates each issue's actual execution — plan, gates, TDD,
reviews, PR, retro — to `ship-issue`, unmodified. It adds no gates of its own
and never bypasses ship-issue's (an epic-level "keep going" is not approval
at any individual PLAN or SHIP GATE — those still stop for the user, per
issue).

## Input

One of:

- A Linear parent issue or project (the epic).
- A spec doc under `docs/specs/` that names one — resolve the epic it points
  to, and carry the spec as context into every issue that links it.

If neither is given, ask which epic — don't guess from recent conversation.

## State — Linear, never conversation memory

Linear is the source of truth for execution state. At the start of every
session — and on any resume, however confident the conversation looks —
re-derive it: list the epic's child issues with their states and blocking
relations. Never act on a remembered issue list; re-read it (issues get
closed, re-scoped, or added by other sessions between runs — a stale list
ships the wrong thing).

## The loop

1. **Pick** the next unblocked issue in dependency order: not Done/Canceled,
   no open blockers. Ties: dependency depth, then priority, then epic order.
2. **Announce** it — ID, title, one line on why it's next — before touching
   anything.
3. **Invoke `ship-issue`** for it. Its PLAN GATE and SHIP GATE fire per
   issue, as real stops.
4. **Record the disposition** after each run: update the spec doc's ledger
   table when one exists (issue → disposition/PR); Linear remains
   authoritative either way.
5. **Continue** — subject to the stop conditions below.

## Stop conditions and pause points

Stop (and summarize) when:

- No unblocked issues remain — everything left is blocked or done.
- A blocker only the user can resolve (missing credential, product decision,
  a contested gate) — surface it and stop rather than inventing an answer.
- The user says stop.

Between issues is a natural pause point: offer to continue rather than
assuming — "ABC-12 shipped; ABC-13 is next unblocked, continue?" A standing
"run the whole epic" from the user turns that offer into a one-liner, not a
skip.

## One writer, one branch

Never run two ship-issue executions in parallel. Finish an issue — or park it
at a gate and say so — before starting the next (two live branches means two
rebases against a moving base and a merge-order fight nobody planned). A
parked issue stays in the summary as its own line, never silently absorbed.

## Re-scoping mid-epic

ship-issue Phase 5 files sibling issues for real-but-out-of-scope work. Those
siblings join the epic's pool automatically at the next state read (step 1
re-lists from Linear) — no manual bookkeeping, and no dropping them because
they weren't in the original decomposition.

## End-of-epic (or end-of-session) summary

Always close with a full roll-up, one row per child issue:

`issue | disposition` — disposition is one of: PR # (shipped), no-code
(closed without a PR, with the reason), blocked (on what), remaining (not
started).

Nothing silently dropped: every issue that was in the pool at any point this
session appears in the table.

## When NOT to use this skill

- One issue, no sequencing needed → `ship-issue` directly.
- Creating or re-scoping the issues themselves → `epic-planning`.
- A question about the epic's status → read Linear and answer; no loop
  needed.
