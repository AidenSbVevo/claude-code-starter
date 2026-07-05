# Style Guide

How to write each part of a Linear issue. Load this file when you need to make
a specific writing call — choice of section, tone of a TL;DR, what belongs in
the description vs. a comment.

---

## Title

- **Verb-led.** "Invalidate the permissions cache on role change…" not "Permissions cache bug."
- **Encode the fix or mechanism**, not just the symptom. "Add cursor pagination to `GET /events`" tells the reader what shipped; "pagination" doesn't.
- **No "fix:" / "feat:" prefixes.** That convention belongs in commit messages, not Linear titles.
- **Under ~80 chars** so it fits in Linear's list view without wrapping.
- **Specific over clever.** "Make batch export ordering deterministic — sort by `(created_at, id)` before serialization" beats "Fix nondeterminism."

---

## TL;DR (header line 1)

- **One sentence.** If you need two sentences, you're describing the resolution, not the ask.
- **Describes the problem or ask, not the answer.** For a bug: what's broken and what fails. For a feature: what's being added and why. For research: what question, and what data or benchmark answers it. For infra: what change and what it unblocks.
- **Stays unchanged for the issue's life.** Typo fixes are fine; meaning changes are not. If the original ask was wrong, prefer closing this issue and filing a new one.

### TL;DR patterns by type

- **Bug:** "<X> fails with <Y> when <Z>, because <one-line cause-hint or impact>."
- **Feature:** "Add <X> to <component> so <user/system> can <do Y>."
- **Research:** "Evaluate/benchmark <X> against <Y> to decide <question>."
- **Infra:** "<Change> to <unblock / enable / fix> <downstream thing>."

---

## Resolution (header line 2)

- **Filled only at close.** Until then: `_(to be filled at close)_`.
- **1–3 sentences, matched to TL;DR granularity.** If the TL;DR is one sentence, write one sentence; don't ship a paragraph.
- **Describes what shipped, not why.** The "why" lives in the TL;DR and the body. The Resolution is the one-line answer.
- **Mention the mechanism and the scope-preserving choices.** "Added `PermissionCache.invalidate(user_id)` and called it from `RoleService.updateRole` after the DB commit; only the mutated user's key is evicted, so other users' warm entries survive" is a good Resolution — it names the change AND the scope choice that made it safe.

---

## Context (always)

Context must be **easy to understand at a glance — by anyone, including someone
outside the project.** Write it as three labeled lines (bold lead-ins, matching
the header style), never as a dense paragraph:

```markdown
## Context
**Background:** <plain-language setup>
**What's happening:** <the problem or ask + inline evidence>
**Why it matters:** <impact / stakes>
```

- **Background — plain-language, always present.** Name what the system, codename,
  or service *is* before using it. "authz-service caches each user's permissions
  in an in-process LRU with a 5-minute TTL…" — not just "The permissions cache is
  stale…". Assume the reader does **not** know the jargon. Background is never
  dropped, even on a trivial issue.
- **What's happening — the problem or ask itself.** Put concrete evidence inline
  here: log excerpts in fenced code blocks, `file.py:line`, request/job/run IDs,
  resource paths.
- **Why it matters — impact up front.** State the stakes: what's blocked, what
  breaks, who's waiting. Don't make the reader infer it from the end of a
  paragraph. On a genuinely trivial issue this may fold into *What's happening*.
- **Keep each line to 1–2 sentences.** Context stays scannable — never a wall of
  text. If a part needs more, it probably belongs in a type-specific section
  (Root cause, Methods, Change…).
- **Link to evidence rather than inlining novels.** A 50-line stack trace? Link to
  the CI run or log stream. A 500-line PDF? Link, don't paste.
- **Skip status narrative.** "Filed this on Friday; we discussed on Monday"
  is comment material, not Context.

---

## Section choice — when to use which

### Repro (bug only)
- Numbered steps a teammate can follow on a fresh machine
- Include the exact command, expected output, actual output
- If the bug is data-dependent, include the smallest input that reproduces it

### Root cause (bug)
- The *why*, not the *what*
- File path + line numbers
- The mechanism in one paragraph — what code path, what assumption it violates

### Fix (bug)
- The *what* — file changes, design decisions
- Include scope-preserving choices ("we only touched X to avoid invalidating Y's cache")

### Scope (feature)
- What's IN this issue. Bulleted, concrete.

### Out of scope (feature)
- What's NOT — even if obviously related
- This section is for the reviewer. Without it, expect "what about X?" comments.

### Implementation (feature)
- Approach, files to touch, ordering of the work
- Not a step-by-step plan — just enough to convince a reviewer the design is sound

### Analysis goals (research)
- Numbered. Each goal is a deliverable, not a step.

### Methods (research)
- Tools, parameters, thresholds
- Mention specific tools/functions: `pytest-benchmark`'s `benchmark` fixture, not "benchmarking"
- Specify thresholds: `p99 < 50ms`, not "fast enough"

### Deliverables (research)
- Where the outputs land: repo paths, notebook paths, doc/RFC pages
- Should be concrete enough that someone else could find them six months later

### Change (infra)
- The actual change — Terraform paths, AWS resources, IAM updates
- Specific account IDs, region names, ARN patterns

### Blast radius (infra)
- What else this touches. Required.
- Includes: services affected, regions, accounts, downstream consumers
- "None" is a valid answer — but justify it

### Rollback (infra)
- The exact revert plan: commands or PR-revert
- Include what's safe vs. what's risky to roll back after merging

### Verification (bug / infra)
- Checkboxes with one-line evidence per check
- The evidence is what distinguishes a real verification from a wish

### Acceptance (feature / research)
- User-visible / caller-visible criteria
- Same checkbox-with-evidence pattern as Verification

### Links (optional)
- Related Linear issues (use `<issue id="...">ENG-NNNN</issue>` or markdown link)
- Design docs, RFCs, runbooks
- Upstream issues in other repos (`org/service#312`)

PRs are linked via Linear's GitHub integration (branch name containing the issue ID, or "Closes ENG-NNNN" in the PR description) — not manually in the Links section.

---

## What goes in comments, NOT the description

The description is the **durable record** of the issue. Comments are the
**conversation**. When in doubt, use comments for anything that:

- Has a timestamp ("on Monday the lead said…")
- Quotes a chat thread or a meeting
- Is a status update during the work ("blocked on infra — pinging @platform")
- Is debugging narrative ("tried X, didn't work, trying Y")
- Asks a clarifying question

If you find yourself writing "FYI from standup…" in the description, that's a
comment.

---

## Owner resolution

Owner is tracked via Linear's native `assignee` field — not in the issue
description. To resolve from git:

1. `git config user.email` → e.g. `you@example.com`
2. `mcp__claude_ai_Linear__list_users(query=<email>)` → returns one user with id + name
3. Use that user's id as the Linear `assignee`

If the email doesn't resolve to a Linear user (e.g., contractor without a
Linear seat), default the assignee to the prompter — the user asking the
skill.

---

## Status semantics

Status is tracked exclusively via Linear's native `state` field — not in the
issue description. The valid values follow Linear's lifecycle:

- **Backlog** — not scheduled
- **Todo** — scheduled but not started
- **In Progress** — actively being worked on
- **Blocked** — work paused on external dependency (note the blocker in a comment)
- **In Review** — PR open, awaiting review
- **Merged** — PR merged but verification still in flight
- **Done** — fully resolved, verification complete
- **Cancelled** — not pursuing; explain why in a comment

The Resolution line is written when transitioning to **Done**, not Merged.
"Merged" means the code shipped; "Done" means it shipped *and* worked.

---

## Common writing mistakes

- **TL;DR as a paragraph.** It's one sentence. Always.
- **Resolution at creation.** Wait until close.
- **Repro in a feature/research/infra issue.** Repro is bug-specific. Use Methods, Scope, or Change.
- **Acceptance with no evidence.** `- [x] Tests pass` is not verification. `- [x] Tests pass (`pytest tests/authz/test_role_change.py` on commit `abc1234`)` is.
- **Description with status narrative.** "We started on Monday, ran into X on Tuesday…" → that's all comments.
- **Out-of-scope omitted on features.** This is the single most common reviewer-question avoider. Always include it.
- **Blast radius "none" without justification.** If the answer is genuinely "none," write "Net-new repo, no existing consumers." Not just "none."
- **Context as a dense blob.** If your Context is one unbroken paragraph mixing situation, evidence, and impact, restructure it into the three labeled lines (Background / What's happening / Why it matters).
- **Background that assumes insider knowledge.** "The permissions cache is stale…" leaves an outsider lost. Name what the cache *is* first. The Background line exists precisely so a reader new to the project can follow.

---

## When the skill should ASK the user vs. infer

**Always ask if missing:**
- Type (if not obvious from prompt)
- Project (if can't be inferred from git remote + Linear project list)
- Priority (default Medium if user shrugs)

**Infer (and confirm in the draft):**
- Owner (from git user.email)
- Title (draft a verb-led summary from the prompt)
- Type-specific section content (from git diff, PR, recent commits)

**Never make up:**
- File paths or line numbers — if you don't have them, write `<path:line>` and let the user fill them
- Project codenames, ticket IDs, run IDs — these get cross-referenced and must be exact
- PR URLs — fetch with `gh pr view`, don't construct
