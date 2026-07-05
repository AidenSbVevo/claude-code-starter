---
name: ship-issue
description: "Drive a Linear issue end-to-end to a shipped PR: plan + decorrelated review, PLAN GATE, TDD, diff review, SHIP GATE, PR, Linear update, mandatory retro. Use when the user wants to start, implement, work, address, take on, or ship a Linear issue \u2014 'start ABC-123', 'work this issue', 'take ABC-42 to a PR'. Prefer over ad-hoc implementation when a Linear issue ID is the starting point."
---

# ship-issue — Linear issue → shipped PR

This skill is an **orchestrator**: the real work is done by capabilities that
live elsewhere (`Explore` agents, `superpowers:test-driven-development`,
`superpowers:brainstorming`, `/simplify`, `/review`, and the `cross-review`
skill). This skill's value is the **sequence, the two gates, and the retro** —
so the disciplined flow runs every time without re-deciding it. If a named
skill or command is absent in this environment, do the equivalent inline and
say so.

Create a TodoWrite list of the phases below at the start so progress is
visible and nothing gets skipped.

## The two gates (the spine)

Run autonomously *between* these two points; stop for explicit user sign-off
*at* them:

1. **PLAN GATE** — after decorrelated plan review, before any code.
2. **SHIP GATE** — after diff review passes, before commit + push + PR
   (outward-facing, hard to reverse).

Both gates are a real stop — `AskUserQuestion` or an explicit wait for the
user's turn. **Never a printed "GATE" banner that gets walked past in the same
turn.** Everything between the gates runs without stopping unless something
genuinely blocks; surface blockers rather than inventing answers to questions
only the user can settle.

## One-writer rule

Claude is the only agent with write access to the tree. Codex (via
cross-review) reviews read-only, always. Two writers is how these setups die.

---

## Phase 0 — Intake

1. Resolve the issue ID from the user's message; if absent, ask.
2. Fetch it from Linear with relations. Read description, priority, parent,
   attachments.
3. Route to the right repo (multi-repo hub: follow the hub `CLAUDE.md`
   routing; ambiguous: ask), then `cd` into it.
4. Restate in 1–2 sentences what the issue actually asks. If it describes a
   symptom with unknown root cause, note it — Phase 5 will likely split
   something out.
5. **Fresh-base check:** `git fetch origin`, then
   `git rev-list --count HEAD..origin/main`. If behind — especially in a
   worktree — update onto `origin/main` *before* investigating. Plans written
   against a stale base get thrown away. Announce the base SHA.
6. Scan related/blocking/sibling issues for scope overlap or already-merged
   work before deep-diving.

## Phase 1 — Investigate

Understand before planning. Dispatch `Explore` agents (or read directly for a
small change): entry points, data flow, where the bug or feature lives, every
consumer a change would touch. Bugs: find the **root cause**, not the symptom.
Contract/config/feature-gate changes: **enumerate every entry point and call
site** — including deploy and launch scripts, not just runtime routes. Return
file:line references concrete enough to plan against without re-exploring.

## Phase 2 — Plan

Draft to `.plans/<issue-id>.md` (scratch — never committed): the change, files
touched, test strategy, constraints the repo `CLAUDE.md` enforces, open
questions. Genuinely open-ended feature → `superpowers:brainstorming` first.

## Phase 3 — Decorrelated plan review

Two independent lenses, in parallel where possible:

- **cross-review, plan mode** (Codex — the decorrelated lens). Packet: the
  plan + acceptance criteria + Phase 1 file:line pointers.
- **One Claude reviewer subagent** with a distinct domain lens where the
  change warrants it (soundness/security, or a domain specialist for infra /
  pipelines).

Reconcile: verify any claim that would change the plan against the actual
code; adopt what's grounded. **When both reviewers independently flag the same
thing, treat it as a strong signal — resolve it at the gate, don't override it
silently.** Carry contested items (claim vs. counterclaim) into the gate
summary.

## Phase 4 — PLAN GATE (hard stop)

Present: the finalized plan, what changed from the draft, key decisions, and
unresolved cross-review escalations. Get explicit approval. Revise and
re-confirm if pushed back.

On approval, in this order:
1. **Branch** off freshly-fetched `origin/main`, per the repo `CLAUDE.md`
   branch convention; absent one, `<handle>/<issue-id>` lowercase, where
   `<handle>` is the local-part of `git config user.email`. Never rename an
   existing branch onto the task. Announce branch + base SHA.
2. **Move the Linear issue to In Progress.** The issue reflects active work
   from the moment coding starts, not at ship time.

## Phase 5 — Scope hygiene

Work that's real but out of scope (root cause behind a symptom, follow-up,
refactor): **file a sibling Linear issue** — same parent, related-to this one,
clear scope statement, the requirements discovered — rather than silently
growing the PR. Note in the plan why this PR is complete without it.

## Phase 6 — Test-plan review

Enumerate the concrete red tests the plan implies (name + what each asserts)
before writing any. Review the set — full parallel reviewers for large
changes, a single reviewer or a self-check against this list for small ones:

- every test earns its place (cut count-inflation and duplicate coverage)
- pins real behavior a plausible regression would break
- honors intent in *neighboring existing tests* (don't contradict an old
  guarantee)
- the high-value missing edge cases — empty/null, boundaries, failure paths —
  not an ocean of hypotheticals

Autonomous (no user gate); if it materially changes scope, say so.

## Phase 7 — Implement (red/green TDD)

Invoke `superpowers:test-driven-development` and follow it strictly: failing
test first, fail for the right reason, minimal code to green, refactor. Small
increments; suite green after each. Match the repo's test layout (find a
sibling test and mirror it). Repo `CLAUDE.md` contract/design rules are gates,
not suggestions.

No-unit-test changes (Terraform, pure config): substitute a **real dry-run**
for red/green — `terraform plan`, schema validation, a parse of rendered
output. Bare `validate` is not verification.

This is the verifier loop — iterate against tests/types/lint as many times as
it takes.

## Phase 8 — Simplify

`/simplify` on the diff. Apply the grounded findings, note skips with reasons,
re-run tests to green.

## Phase 9 — Decorrelated diff review

1. `/review` — Claude's own critical pass + specialists. Apply auto-fixes;
   verify adversarial findings against the code before acting; add a
   regression test with each real fix.
2. **cross-review, diff mode** (Codex): discovery → triage → apply FIXes →
   hard gates to green → single verification pass, per that skill's loop
   policy. Bounded by design — do not extend the loop here.

Behavior-changing judgment calls and surviving contested findings are **held
for the SHIP GATE**, not resolved autonomously.

## Phase 10 — SHIP GATE (hard stop)

Confirm with the user before anything outward-facing. The summary must:

- **Map each acceptance criterion to the test that exercises it.** Explicitly
  label anything only *assumed* or *manually verified*. Never claim a path is
  covered unless a test actually runs it — an overstated coverage claim is
  worse than an honestly flagged gap.
- Show contested cross-review findings as claim vs. counterclaim for the
  user's call.
- Multi-ticket runs: roll up every ticket's disposition so nothing is
  silently dropped.

## Phase 11 — Ship

1. `git fetch origin && git rebase origin/main`; resolve conflicts; re-run the
   suite to green. Never push onto a base that has moved.
2. Stage only files belonging to this change. **Exclude `.plans/` and
   `.review/`.** Never `git add -A` blindly.
3. Commit per the repo's message convention, referencing the issue and any
   split-out siblings. Honor the attribution rule in the global/repo
   `CLAUDE.md`.
4. Push `-u origin <branch>`.
5. `gh pr create --body-file` (not inline) with a real body: what/why, key
   pieces, testing, sibling links. If the call fails mid-flight, **check
   `gh pr view` before retrying** — don't create a duplicate.

## Phase 12 — Linear update

Attach the PR to the issue. It's been In Progress since the plan gate; only
re-assert state if something reverted it.

## Phase 13 — RETRO (mandatory — ~5 minutes, before declaring done)

Read `.review/journal.md` (this issue plus recent ones) and answer three
questions:

1. **Promote:** has any finding class now appeared **≥2 times across
   issues**? Draft the exact diff — a repo `CLAUDE.md` rule, or an edit to one
   of these skills — show it, apply on approval. A lesson that isn't a diff
   will be relearned.
2. **Demote:** did any pipeline rule fire zero times across recent issues
   while costing friction? Propose removing or relaxing it. Scar tissue pays
   rent or comes out.
3. **Calibrate:** what did cross-review's verification round actually catch?
   Consistently empty → evidence the caps are right. Consistently real →
   evidence to revisit them.

Append one line to the journal:
`RETRO <issue>: promoted <n>, demoted <n>, r2-yield <n>`.
The output of this phase is **config diffs, not prose**.

## Phase 14 — Optional extras (only when asked)

- **Live verification:** follow repo `CLAUDE.md` conventions for dev servers;
  never point destructive tests at a production-backed service; **timebox** —
  if a flow wedges, report and stop rather than looping.
- **CI watch + merge:** poll once after a `sleep`, never stream-watch. Merge
  only on green. In a worktree, merge **without** `--delete-branch` (the
  auto-checkout of main fails); delete the remote branch as a separate step.
  Afterwards, state the resulting git/worktree state explicitly.

---

## Conventions this skill always honors

Re-read the global `~/.claude/CLAUDE.md` and the repo/hub `CLAUDE.md` at the
start of a run — they override anything written here. Durable rules:

- **Fresh base**, at intake and again before push. The single most repeated
  source of friction in pipelines like this; treat it as hard.
- **One writer** — Codex never writes (see cross-review).
- **Bounded critic loops** — cross-review's caps are policy, not defaults.
- **TDD is not optional** for features, bug fixes, and refactors (throwaway
  scripts and pure config excepted, with a dry-run substitute).
- **Scratch stays out of git** — `.plans/`, `.review/`.

## Scaling the flow

Match effort to the ticket. A one-file config fix: collapse Phases 1–3 into a
quick read plus a single cross-review plan pass (or skip Codex entirely), keep
both gates. A multi-file feature or anything touching auth, data, contracts,
or user-visible behavior: full pipeline. When unsure, lean full.

## When NOT to use this skill

- Investigation/debugging with no intent to ship yet.
- A question about a ticket → just answer.
- Linear CRUD without implementation.
- Work not anchored to a Linear issue → normal dev flow (brainstorm → TDD →
  /simplify → /review) without the Linear bookends, but keep the cross-review
  checkpoints.
