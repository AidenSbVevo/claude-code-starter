---
name: ship-issue
description: "Drive a Linear issue end-to-end to a shipped PR: plan + decorrelated review, PLAN GATE, TDD, diff review, SHIP GATE, PR, Linear update, mandatory retro. Use when the user wants to start, implement, work, address, take on, or ship a Linear issue — 'start ABC-123', 'work this issue', 'take ABC-42 to a PR'. Also accepts a spec path or plain description (anchorless mode). Prefer over ad-hoc implementation when a Linear issue ID is the starting point."
---

# ship-issue — Linear issue → shipped PR

This skill is an **orchestrator**: the real work is done by capabilities that
live elsewhere (`Explore` agents, `superpowers:test-driven-development`,
`superpowers:subagent-driven-development`, `superpowers:brainstorming`,
`/simplify`, `/code-review`, and the `cross-review` skill). This skill's value
is the **sequence, the two gates, and the retro** — so the disciplined flow
runs every time without re-deciding it. If a named skill or command is absent
in this environment, do the equivalent inline and say so.

Phase 0 declares the tier (fast/full) and builds the TodoWrite list from that
tier's phase set, so progress is visible and every phase the tier includes
actually runs. Gates and retro appear in every tier.

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

1. Resolve the anchor from the user's message: a Linear issue ID, a
   spec/design-doc path, or a plain description (see **Anchorless mode**
   below). Ambiguous: ask.
2. Linear-anchored: fetch the issue from Linear with relations. Read
   description, priority, parent, attachments.
3. **Extract the acceptance criteria AND the issue's `## Verification`
   commands.** If either is absent or unfalsifiable, derive checkable AC
   yourself and confirm them at the PLAN GATE — the SHIP GATE maps criteria to
   tests and runs Verification verbatim, and vague AC here degrades that
   mapping to vibes.
4. If the issue carries a `## Spec` link, read that section before Phase 1 and
   include it in every cross-review packet.
5. Route to the right repo (multi-repo hub: follow the hub `CLAUDE.md`
   routing; ambiguous: ask), then `cd` into it.
6. Restate in 1–2 sentences what the issue actually asks. If it describes a
   symptom with unknown root cause, note it — Phase 5 will likely split
   something out.
7. **Declare the tier — fast or full** (criteria under *Scaling the flow*) —
   and build the TodoWrite list from that tier's phase set. Gates and retro
   appear in every tier; the tier scales ceremony, never the spine.
8. **Fresh-base check:** `git fetch origin`, then
   `git rev-list --count HEAD..origin/main`. If behind — especially in a
   worktree — update onto `origin/main` *before* investigating. Plans written
   against a stale base get thrown away. Announce the base SHA.
9. Scan related/blocking/sibling issues for scope overlap or already-merged
   work before deep-diving.

## Phase 1 — Investigate

Understand before planning. Dispatch `Explore` agents (or read directly for a
small change): entry points, data flow, where the bug or feature lives, every
consumer a change would touch. Bugs: find the **root cause**, not the symptom.
Contract/config/feature-gate changes: **enumerate every entry point and call
site** — including deploy and launch scripts, not just runtime routes. For a
UI affordance, confirm it's actually reachable on the target surface (web vs
CLI) before planning a change to it (assuming CLI code is the web path is a
recurring trap). Return file:line references concrete enough to plan against
without re-exploring.

## Phase 2 — Plan

Draft to `.plans/<issue-id>.md` (scratch — never committed): the change, files
touched, test strategy, constraints the repo `CLAUDE.md` enforces, open
questions.

Genuinely open-ended feature → invoke `superpowers:brainstorming` first,
**scoped**: run its checklist items 1–8 only (context → questions → approaches
→ design approval → spec at `docs/specs/<issue-id>-<topic>.md` → self-review →
user spec review). Its item 9 ("invoke writing-plans") is **replaced by
returning control to this skill** — ship-issue, not brainstorming, owns what
happens after the spec. Put the override in the invocation itself: "You are
running inside ship-issue, which owns the pipeline. After the user approves
the spec, STOP — do not invoke writing-plans or any other skill; report the
spec path back. Create checklist tasks for items 1–8 only." Before committing
the spec, create this issue's branch per Phase 4 step 1 (branch creation moves
earlier for this tier; announce it, skip re-branching at the PLAN GATE) — a
spec never lands on main.

**Plan format tiers.** Small (≤2 files, no new interfaces): the loose
`.plans/` draft suffices. Large (≥3 distinct tasks, new interfaces, or
anything you'd hesitate to hold in one context window): write
`.plans/<issue-id>.md` in the `superpowers:writing-plans` **format** —
Goal/Architecture/**Global Constraints** header; per-task **Files + Interfaces
(Consumes/Produces, exact signatures)**; bite-sized checkbox steps with
complete code; its No-Placeholders rules and Self-Review. Location and
lifecycle stay ours: `.plans/`, never committed (this is the "user preference"
writing-plans defers to). Do **not** offer writing-plans' execution-choice
menu — Phase 7 decides execution after the PLAN GATE. In the plan header,
replace the stock "REQUIRED SUB-SKILL" line with: "For agentic workers:
execute via superpowers:subagent-driven-development; when all tasks complete,
STOP and return to ship-issue Phase 8 — do NOT invoke
finishing-a-development-branch."

A plan touching schema or data migrations must state its expand/contract
strategy and rollback plan.

## Phase 3 — Decorrelated plan review

Two independent lenses, in parallel where possible:

- **cross-review, plan mode** (Codex — the decorrelated lens). Packet: the
  plan + acceptance criteria + Phase 1 file:line pointers + the governing spec
  section, when one exists. Also ask: **should this plan have been
  large-tier?** — a decorrelated check on the plan-format sizing call.
- **One Claude reviewer subagent** with a distinct domain lens where the
  change warrants it (soundness/security, or a domain specialist for infra /
  pipelines).

**Reviewer floor: at least one independent reviewer, always.** If Codex is
unavailable, the Claude reviewer subagent becomes mandatory — and the gate
summary says so.

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
   existing branch onto the task. Announce branch + base SHA. If Phase 2's
   spec tier already created the branch, skip re-branching — just confirm
   you're on it.
2. **Move the Linear issue to In Progress.** This happens at PLAN GATE
   approval even when the branch was already created earlier by Phase 2's spec
   tier — gate approval, not branch creation, is the start-of-work signal.
   (No Linear issue → skip; see Anchorless mode.)

## Phase 5 — Scope hygiene

Work that's real but out of scope (root cause behind a symptom, follow-up,
refactor): **file a sibling Linear issue** — same parent, related-to this one,
clear scope statement, the requirements discovered — rather than silently
growing the PR. Note in the plan why this PR is complete without it.
(Anchorless: append to the plan's `## Split out` list instead.)

Also check the planned — and later the actual — diff against the issue's
`## Non-goals`: drifting into a declared non-goal is scope creep even when
it's adjacent to the change.

## Phase 6 — Test-plan review

Enumerate the concrete red tests the plan implies (name + what each asserts)
before writing any. Review the set — full parallel reviewers for large
changes, a single reviewer subagent for small ones. **One subagent reviewer is
the floor even for small changes** — a self-check by the plan's author is the
correlated failure this pipeline exists to avoid. **The reviewer packet
carries the proposed test list AND the existing tests in the areas touched**
(a reviewer who can't see the neighbors approves duplicates and
contradictions). Review for:

- every test earns its place (cut count-inflation and duplicate coverage)
- pins real behavior a plausible regression would break
- honors intent in *neighboring existing tests* (don't contradict an old
  guarantee)
- the high-value missing edge cases — empty/null, boundaries, failure paths —
  not an ocean of hypotheticals

Autonomous (no user gate); if it materially changes scope, say so.

## Phase 7 — Implement (red/green TDD; SDD for large plans)

Invoke `superpowers:test-driven-development` and follow it strictly: failing
test first, fail for the right reason, minimal code to green, refactor. Small
increments; suite green after each. Match the repo's test layout (find a
sibling test and mirror it). Repo `CLAUDE.md` contract/design rules are gates,
not suggestions.

**Large issues** (writing-plans-format plan, ≥3 tasks): execute via
`superpowers:subagent-driven-development` instead of inline TDD. Standing
overrides while inside it: (1) its terminal step,
finishing-a-development-branch, is **replaced by returning to Phase 8** —
never present its merge/PR menu; the SHIP GATE and Phase 11 own shipping.
(2) Per-task local commits on the issue branch are allowed; the SHIP GATE
guards push + PR, not local commits. (3) Implementer subagents are Claude and
satisfy the one-writer rule — that rule targets Codex. (4) Copy the
no-AI-attribution rule into every dispatch's global-constraints block. When
SDD ran, its final whole-branch review replaces Phase 9 step 1; Phase 9 step 2
(cross-review diff mode) **still runs** — SDD has no decorrelated reviewer.
/simplify becomes optional (task reviewers cover quality). If the session dies
mid-plan, resume via the SDD ledger (`.superpowers/sdd/progress.md`) or
`superpowers:executing-plans` on the `.plans/` file — prefer these over
handoff when a formatted plan exists.

No-unit-test changes (Terraform, pure config): substitute a **real dry-run**
for red/green — `terraform plan`, schema validation, a parse of rendered
output. Bare `validate` is not verification.

This is the verifier loop — iterate against tests/types/lint as many times as
it takes.

## Phase 8 — Simplify

`/simplify` on the diff. Apply the grounded findings, note skips with reasons,
re-run tests to green. (When SDD ran in Phase 7 this is optional — its task
reviewers cover quality; run it only if the diff still looks baroque.)

## Phase 9 — Decorrelated diff review

1. `/code-review` at an explicit effort level — `high`, or `ultra` for
   full-pipeline tickets — with the pr-review-toolkit specialists
   (`silent-failure-hunter`, `pr-test-analyzer`). Never bare `/review` — that
   command is PR-only in this environment, and no PR exists yet at this phase.
   Apply auto-fixes; verify adversarial findings against the code before
   acting; add a regression test with each real fix. When SDD ran, its final
   whole-branch review replaces this step (see Phase 7).
2. Invoke **cross-review, diff mode** (Codex); its loop policy governs.

Behavior-changing judgment calls and surviving contested findings are **held
for the SHIP GATE**, not resolved autonomously.

## Phase 9.5 — Test-quality review

Code review asks "is the code right"; this asks "would the tests notice if it
weren't." Dispatch `pr-review-toolkit:pr-test-analyzer` with the branch diff,
the acceptance criteria, and Phase 6's reviewed test list. It judges:

1. **Would it actually fail?** For the 1–2 most critical behaviors, do a
   mutation spot-check — invert the condition, drop the guard — and confirm a
   test catches it. A test that can't fail is documentation, not a test.
2. **No tautologies or mock echoes** — never assert that a mock returns what
   it was stubbed to return, never restate the implementation.
3. **The Phase 6 contract survived implementation** — every test the reviewed
   plan called for exists or its cut is justified in one line; failure paths
   and boundaries are the first thing dropped under pressure, so check them
   by name.
4. **Deterministic** — no sleeps, wall-clock, ordering, or network
   dependencies that will flake in CI.
5. **Names state behavior**, not implementation.

Output: a per-criterion quality verdict — **strong / weak / absent** — carried
into the SHIP GATE mapping. Weak or absent on a load-bearing criterion goes
back through Phase 7 before the gate, not into a gate-summary footnote. Runs
in every tier, SDD or inline (SDD's task reviewers check per-task spec
compliance; whole-branch test quality is nobody's job until here).

## Phase 10 — SHIP GATE (hard stop)

Confirm with the user before anything outward-facing. The summary must:

- **Map each acceptance criterion to the test that exercises it, with Phase
  9.5's quality verdict (strong / weak / absent) beside each.** Explicitly
  label anything only *assumed* or *manually verified*. Never claim a path is
  covered unless a test actually runs it — an overstated coverage claim is
  worse than an honestly flagged gap, and "covered" requires at least a
  *weak* verdict, never an absent one.
- **Run the issue's `## Verification` commands verbatim and paste their
  output** in the gate summary. (AC derived at Phase 0: run the checks
  confirmed at the PLAN GATE instead.)
- **User-visible behavior changed → README/docs delta included in the diff, or
  explicitly waived** by the user here.
- Show contested cross-review findings as claim vs. counterclaim for the
  user's call.
- Multi-ticket runs: roll up every ticket's disposition so nothing is
  silently dropped. Anchorless runs: surface the plan's `## Split out` list.

On approval — in the same turn the user grants it, never earlier — create the
marker file `.plans/<issue-id>.approved`. The `hooks/gate-guard.sh` hook
refuses `git push` / `gh pr create` without it; the marker is the machine
record that this gate actually happened.

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
6. **One default check poll:** `sleep` ~60–120s, then `gh pr checks`. Report
   red checks before declaring shipped — red goes to Phase 11.5, not into the
   void. No stream-watching.

## Phase 11.5 — PR follow-through

- **Human review comments** → `superpowers:receiving-code-review`: verify
  claims against the code before implementing, push back with evidence where
  the feedback is wrong, no performative agreement.
- **Red CI** → bounded triage: classify flake vs. real. Real → fix via TDD
  (red test reproducing the failure first) plus a regression test; flake → one
  re-run. Iterate until green or genuinely blocked — then report the blocker
  rather than looping.

## Phase 12 — Linear update

Attach the PR to the issue. If the branch name doesn't match Linear's
auto-link convention, this manual attach is what links them — don't skip it on
the assumption automation caught it. The issue has been In Progress since the
plan gate; only re-assert state if something reverted it. Closing the issue is
deliberately owned by `linear-issues` — merged ≠ Done. (No Linear issue →
skip; see Anchorless mode.)

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
The output of this phase is **config diffs, not prose**. An applied promotion
is **committed and pushed in the config repo in the same retro** — an
uncommitted lesson is lost on every other machine. The global
`~/.claude/CLAUDE.md` is the single home for promoted standing rules.

## Phase 14 — Optional extras (only when asked)

- **Live verification:** follow repo `CLAUDE.md` conventions for dev servers;
  run only the relevant specs, not the whole suite (the suite already ran
  green — this phase verifies the flow, not the world); don't kill or hijack
  the user's already-running processes (dev servers, watchers) without asking;
  never point destructive tests at a production-backed service; **timebox** —
  if a flow wedges, report and stop rather than looping.
- **CI watch + merge:** beyond Phase 11's single default poll, poll again only
  after a `sleep`, never stream-watch. Merge only on green. In a worktree,
  merge **without** `--delete-branch` (the auto-checkout of main fails);
  delete the remote branch as a separate step. Afterwards, state the resulting
  git/worktree state explicitly.

---

## Anchorless mode

The anchor is a parameter, not this skill's identity. Intake accepts a Linear
issue ID, a spec/design-doc path, or a plain description. Without a Linear
issue, the Linear-specific steps become conditional no-ops — Phase 0's fetch,
Phase 4's In Progress move, Phase 5's sibling filing to Linear, Phase 12's PR
attach. Everything else — tiering, gates, decorrelated reviews, TDD/SDD,
retro — runs identically.

- Derive `<issue-id>` as a short slug from the anchor (e.g.
  `fix-relay-token-fallback`) — branch name, plan file, and gate marker all
  key off it.
- Sibling-worthy scope discoveries with no Linear to file into go to a
  `## Split out` list in the plan file, surfaced at the SHIP GATE.

## Conventions this skill always honors

Re-read the global `~/.claude/CLAUDE.md` and the repo/hub `CLAUDE.md` at the
start of a run — they override anything written here. Fresh base, one writer,
bounded critic loops, real gates, scratch-dir hygiene (`.plans/`, `.review/`),
and no AI attribution all live in the global dev-pipeline block — that block
is the single home for them; follow it there rather than a restated copy here
(triple-encoding causes divergence). Rules specific to this skill:

- **TDD is not optional** for features, bug fixes, and refactors (throwaway
  scripts and pure config excepted, with a dry-run substitute).
- **The SHIP GATE marker is written only at approval** — create
  `.plans/<issue-id>.approved` in the turn the user says ship, never earlier;
  `hooks/gate-guard.sh` treats its existence as proof the gate happened.

## Scaling the flow

The tier is declared at Phase 0 intake and fixes the TodoWrite phase set:

- **fast** — a one-file config fix or similarly small, well-understood change:
  collapse Phases 1–3 into a quick read plus a single independent plan review
  (Codex plan mode; Codex unavailable → the Claude reviewer subagent,
  mandatory). Phase 6 runs with a single reviewer subagent.
- **full** — a multi-file feature, or anything touching auth, data, contracts,
  migrations, or user-visible behavior: every phase, full parallel reviews.

Both gates and the retro run in every tier; the Phase 3 reviewer floor holds
in every tier — there is no tier with zero independent review. When unsure,
lean full.

## When NOT to use this skill

- Investigation/debugging with no intent to ship yet →
  `superpowers:systematic-debugging` to find the root cause, then
  `linear-issues` to file what's found, then this skill to fix it.
- A question about a ticket → just answer.
- Linear CRUD without implementation → `linear-issues`.

Work not anchored to a Linear issue is **not** an exclusion — run it through
Anchorless mode.
