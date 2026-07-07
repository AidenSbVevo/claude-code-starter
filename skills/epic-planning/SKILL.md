---
name: epic-planning
description: "Turn a goal, epic, or feature area into one-PR-sized Linear issues with acceptance criteria and verification commands, created only after explicit approval. Trigger: scope, plan, break down, decompose, or create issues/tickets for an epic or feature area \u2014 'scope out the memory epic', 'break this into tickets', 'plan the issues for X'. Not for implementing an issue (ship-issue) or one-off edits."
---

# epic-planning — goal → well-formed Linear issues

An epic decomposed against imagined architecture wastes every downstream
phase. Investigate before decomposing. And write acceptance criteria *now*,
before an implementation exists to bias them — the criteria written here are
the contract that ship-issue's reviews and SHIP GATE check against. Vague
criteria here become vibes-based review later.

## Phase 0 — Pin the goal

- If the goal is open-ended (real design latitude), invoke
  `superpowers:brainstorming` first, **scoped**: run through spec-commit and
  user spec review (items 1–8), spec at `docs/specs/YYYY-MM-DD-<epic>.md`;
  then STOP — item 9 is replaced by returning here for Phase 1.
  writing-plans plans single implementations; this skill decomposes epics —
  the spec is brainstorming's deliverable *to* us, not a handoff of control.
  Say so in the invocation: "Running inside epic-planning; after spec
  approval, return the spec path — do not invoke writing-plans." If
  brainstorming's scope check flags multiple independent subsystems, capture
  that decomposition in the spec and carry it into Phase 2 — do not let it
  spawn per-subsystem brainstorm→plan cycles.
- Restate the epic goal in 2–3 sentences. If the epic is being invented in
  this conversation (not read from Linear), confirm the restatement with the
  user before investing in investigation.

## Phase 1 — Investigate reality

- If the repo maintains an architecture map (see repo `CLAUDE.md`), read it
  first. Then dispatch `Explore` agents for the areas the epic touches: entry
  points, data flow, the seams where new work attaches, and constraints the
  repo enforces (contracts, conventions, test layout).
- Output: file:line pointers concrete enough that issues can cite them.
- Small, well-understood epics: a direct read is fine; don't ceremonialize.

## Phase 2 — Decompose

Rules:

- **One issue ≈ one context window ≈ one PR.** That window includes
  ship-issue's own review ceremony (plan review, gates, diff reviews, retro
  — several model passes), so budget roughly half a window of actual
  implementation per issue. If finishing an issue would require compaction,
  it's two issues. Sizing is a first-class property, not an afterthought.
- Spikes are legitimate issues — but their deliverable is a decision or
  document, and they're labeled as such so nobody TDDs an investigation.
- Order by dependency; record blocking relations explicitly.

Every implementation issue uses this template:

```
## Goal
(1–2 sentences: what changes and why)

## Context
(file:line entry points from Phase 1 — where this work attaches)

## Spec
(link to `docs/specs/<file>#<section>` this issue implements — "none" if
the epic had no brainstormed spec)

## Acceptance criteria
- [ ] (enumerated; each one independently checkable)

## Verification
(exact commands that prove "done" — test invocations, dry-runs; include at
least one negative/failure case, not just the happy path)

## Non-goals
(where scope would creep if unstated)

## Sizing
(one line: why this fits one PR)
```

## Phase 3 — Cross-check the decomposition

Recommended for anything multi-week; skip for small epics. Invoke
**cross-review in plan mode** with: the epic goal, the issue list (titles +
goals + acceptance criteria), the dependency order, and the Phase 1 pointers.
Ask specifically for: missing work, mis-sequencing, issues that look bigger
than one PR, and criteria an implementer could satisfy two different ways.

Triage per cross-review's rules and fold FIXes into the decomposition.
**Single discovery pass only — no verification round.** Plans are cheap to
regenerate; the bounded-loop machinery is for code.

## Phase 4 — GATE, then write to Linear

Present the summary table — `issue | goal | size | depends on` — plus any
contested cross-review items, and get **explicit approval before creating
anything in Linear**. Bulk-creating issues is outward-facing.

On approval: create the epic/parent per team convention, the issues from the
template, and the relations. Report the created IDs.

When a spec exists (Phase 0), write the created IDs back into the spec doc
as a ledger table — `issue | goal | state` — so the spec tracks its own
execution instead of drifting the moment issues exist.

This skill ends at created issues. `execute-epic` is the follow-on: it
picks the next unblocked issue and drives the epic through successive
ship-issue runs.

## Conventions

Defer to the repo/hub `CLAUDE.md` for team, labels, project fields, and
whether an epic is a Linear project or a parent issue. This skill owns the
*structure* of good issues, not the team's taxonomy.

## When NOT to use this skill

- Implementing an existing issue → `ship-issue`.
- Editing, closing, or commenting on single issues → plain Linear tools.
- A question about what an epic involves → just answer it.
