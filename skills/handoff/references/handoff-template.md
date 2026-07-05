# Handoff template

Used by the `handoff` skill to compose `HANDOFF.md` at the repo root. Each
section has guidance for what to fill in and what to leave out. Aim for
~150 lines total — terse, specific, bullet points over prose.

---

```markdown
---
generated_by: handoff-skill
generated_at: <ISO-8601 UTC>
session_summary: <one-line summary of this session, no quotes inside>
project: <repo dir name>
branch: <git branch>
last_commit: <short-sha>
---

# Handoff — <Project Name> · <YYYY-MM-DD HH:MM TZ>

> [!important] You are a fresh Claude Code session inheriting in-flight work.
> Do NOT start changing code until you have followed the START HERE reading
> order below. The previous session built up context that lives partly in
> these docs and partly in the actual code files. Read both.

## START HERE — Reading order

Read in this order before doing anything else:

1. **This entire HANDOFF.md** — top to bottom. The later sections (Things to
   AVOID, Open questions, Suggested next concrete action) are where the
   irreplaceable session-specific knowledge lives.
2. **Architecture / docs** (skip any that don't exist):
   - `architecture/state.md` — current snapshot, working features, in-flight
     work, stack, key pointers
   - `architecture/plans.md` — user-owned roadmap
   - `architecture/decisions.md` — material decisions and their *why*
   - `README.md` — install / configure / run
3. **The actual code files this session touched** (read these before
   modifying anything — docs describe, code IS):
   - `<path/to/file.py>` — <one-line why it matters>
   - `<path/to/another.py>` — <one-line why>
   - `<path/to/test.py>` — <one-line why>
4. **Verify the project still works** before making any change:
   ```bash
   <test command from architecture/state.md or README>
   ```
   If anything fails, surface it to the user before proceeding.

After all of the above, summarize what you understood and propose your
first move. **Do not skip the summarize step** — it's the user's checkpoint
to redirect if you misread something.

## What this project does

<2-3 sentences. Pulled from architecture/state.md TL;DR or README's first
paragraph. Tighten — this is for orientation, not a sales pitch.>

## What we worked on this session

<3-8 bullets, concrete and outcome-focused. Commits landed, files
created/modified, decisions agreed. Standup-style. NOT a tool-call replay.>

- <bullet 1>
- <bullet 2>
- <bullet 3>

## Current state of work

- **Branch:** `<branch>`
- **Last commit:** `<short-sha>` <subject> (<relative date>)
- **Commits this session:** `<sha1>`, `<sha2>`, … (or "none — work in
  progress, not yet committed")
- **Uncommitted changes:**
  - `<file 1>` — <one-line description of what changed and why>
  - `<file 2>` — <one-line>
  - (or "(none)")
- **Untracked files we created:**
  - `<file>` — <one-line>
- **Tests:** `<N>/<N> passing as of <relative time>` (or "not run this
  session; the next session should verify with `<command>` before changes")

## How to run

<Commands from architecture/state.md, HANDOFF.md, or README. Keep to the
top 2-3 most useful ones — full reference is in the README. Include the
production-config command if there is one.>

```bash
<command 1>
<command 2>
```

## Environment / credentials

<What the next session needs in `.env` or the shell environment. Reference
`.env.example` if it exists. NEVER include actual values.>

- `<ENV_VAR_1>` — <purpose>
- `<ENV_VAR_2>` — <purpose>
- Virtualenv path: `<.venv path>` (Python `<version>`)

## Active workstreams

<Open Linear issues tied to this repo, if a Linear project resolves.
Format: `[SOFT-NNNN](url) <title> · _<status>_`. Omit section entirely if
no Linear project found — don't insert "(none)" filler.>

- [SOFT-NNNN](https://linear.app/...) <title> · _In Progress_

## Decisions made this session (not yet fully in code)

<Things you and the user agreed on in conversation but that aren't (or
aren't fully) reflected in code yet. Critical because the next session
would otherwise re-debate them. Include WHY for each.>

- <decision 1 — and *why* it was chosen>
- <decision 2>

## What was tried and rejected

<Approaches you started and pivoted away from. Include the REASON — without
it, the next session will rediscover the rejected approach.>

- **<approach 1>** — rejected because <reason>
- **<approach 2>** — rejected because <reason>

## Things to AVOID

<The most valuable section. Pull aggressively from session signals:
explicit user corrections, observed failures, confirmations of non-obvious
choices ("yes that was right" = keep doing it). Be specific.>

- **DO NOT** <thing>. Reason: <user feedback or observed failure>.
- **DO NOT** <thing>. Reason: <…>.
- **DO** <thing the user explicitly endorsed>. Reason: <…>.

## Open questions waiting on user input

<Things the next session needs the user to weigh in on before proceeding.
If none, write `_(none)_`.>

- <question 1>
- <question 2>

## Suggested next concrete action

<ONE specific change to make next. With file paths if possible. Resist
listing 5 things — the next session can read plans.md for the roadmap. This
is the immediate next move.>

<one paragraph or a single labeled bullet>
```

---

## Filling guidance for the skill

- **session_summary** field: one line, ~10-15 words, describing what made
  this session matter. Examples: "Bootstrapped architecture/ folder and
  landed Phase 3 data-quality pass" or "Wired up auth middleware and
  debugged the session-token regression."

- **START HERE — code files:** be selective. List 3-7 files max. The
  files the session actually modified (`git diff --name-only HEAD~N`) are a
  good starting point, but cull: a test file rarely needs its own bullet
  if its tested module is already listed. Prefer the centerpiece files.

- **What we worked on:** lead with verbs. "Added X", "Fixed Y", "Refactored
  Z", "Decided to use W over V." Pass each bullet the test: would this be
  useful to the next session, or is it just narrative? Cut narrative.

- **Things to AVOID:** the temptation is to be polite. Resist it. The next
  session is better served by *"don't run the test suite without
  `--maxfail=1` — full failures are 200 lines and useless"* than by
  *"consider being mindful of test output volume."* Be direct.

- **Suggested next concrete action:** if you genuinely don't know what's
  next, write "Confirm with user — multiple paths possible. See [Open
  questions] above." Don't fabricate a next action just to fill the slot.
