# Canonical Linear Issue Template

This is the exact shape every Linear issue in the Engineering team (prefix
`ENG-`) should follow. The skill draws from this file when drafting issues
during the CREATE and CLOSE flows.

## Universal structure (every issue)

```markdown
**TL;DR:** <one sentence describing the problem or ask — written at creation, never rewritten>
**Resolution:** _(to be filled at close)_

---

## Context
**Background:** <plain-language setup — name what the system/codename IS so a reader without insider knowledge can follow>
**What's happening:** <the problem or ask itself; evidence (logs, file:line, run IDs, resource paths) goes inline here>
**Why it matters:** <impact / stakes — what's blocked, what breaks, who's waiting>

<type-specific body sections — see below>

## Links

- Related: <related Linear issues, design docs, RFCs, runbooks>
```

### Header semantics

The header is exactly **two lines** above the `---` divider:

- **Line 1 — TL;DR.** One sentence. Describes the *ask* or *problem*, not the resolution. Preserved across the issue's life. The skill rewrites only typos / clarity tweaks; meaning-preserving edits only.
- **Line 2 — Resolution.** Starts as `_(to be filled at close)_`. At close, 1–3 sentences explaining what shipped. Granularity should match the TL;DR (don't write a paragraph if the TL;DR was a sentence).

Status, Type, Owner, Project, and PR are tracked via Linear's native fields — do not duplicate them in the description body.

### Context structure

`## Context` is **always** three labeled lines (bold lead-ins, matching the header style). The goal is that anyone — including someone outside the project — can understand the situation at a glance:

- **Background** — plain-language setup. Name what the system / codename / service *is* ("authz-service caches each user's permissions in an in-process LRU…"). Never assume the reader already knows the jargon. **Always present**, even on trivial issues.
- **What's happening** — the problem or ask itself. Evidence (log excerpts in fenced blocks, `file.py:line`, run/job IDs, resource paths) goes inline here.
- **Why it matters** — the impact or stakes, stated up front: what's blocked, what breaks, who's waiting.

Each line is **1–2 sentences** — Context must stay scannable, never a wall of text. On a genuinely trivial issue, *Why it matters* may fold into *What's happening*, but *Background* is never dropped. See `style-guide.md` for the full rules and `examples.md` for worked Context across all four types.

### Required at every state

- Header (2 lines: TL;DR + Resolution)
- `## Context`
- `## Links` (optional — include only when there are related issues, docs, or other references worth tracking)

That's the minimum. Everything else is type-specific and optional at open.

### Required at close

When the skill transitions an issue to Done, the following must be populated
(the skill blocks the close until they are):

- `Resolution:` line in the header (1–3 sentences)
- Type-specific Verification or Acceptance section (checkboxes with evidence)

The merged PR should be linked via Linear's GitHub integration (branch name containing the issue ID, or "Closes ENG-NNNN" in the PR description), not manually in the issue body.

---

## Type variants

The body between `## Context` and `## Links` changes by type.

### Bug

```markdown
## Context
**Background:** <what the affected system/service is, in plain language>
**What's happening:** <what's broken — symptom, when it started, evidence/logs inline>
**Why it matters:** <impact — what's blocked or failing because of it>

## Repro
<numbered steps to reproduce — environment, command, expected vs actual>

## Root cause
<the why — file paths and line numbers, mechanism>

## Fix
<the what — file changes, design decisions, scope boundaries>

## Verification
- [ ] <how the fix is confirmed — smoke test, regression check, log inspection>
- [ ] <…>
```

### Feature

```markdown
## Context
**Background:** <what the system/component is today, in plain language>
**What's happening:** <the gap or need — what's missing and who asked>
**Why it matters:** <impact — what this unblocks or enables>

## Scope
<what's in, what's out — explicit boundaries>

## Implementation
<approach, files touched, design decisions, ordering of the work>

## Out of scope
<what this issue is NOT — keeps reviewers from asking>

## Acceptance
- [ ] <user-visible criterion>
- [ ] <…>
```

### Research

```markdown
## Context
**Background:** <what the dataset/system/project is, in plain language>
**What's happening:** <the question and what data or benchmark answers it>
**Why it matters:** <impact — what decision or next step this gates>

## Analysis goals
1. <goal>
2. <goal>

## Methods
<tools, parameters, approach, key thresholds>

## Deliverables
<notebook path, report doc, repo paths, RFC>

## Acceptance
- [ ] <analysis stage completed and committed>
- [ ] <report or notebook delivered>
```

### Infra

```markdown
## Context
**Background:** <what the resource/system is, in plain language>
**What's happening:** <why this change is needed — upstream issue, current failure>
**Why it matters:** <impact — what's blocked or at risk until it lands>

## Change
<the concrete change — Terraform paths, AWS resources, IAM role updates, ECR repos>

## Blast radius
<what else this touches — accounts, regions, downstream services>

## Rollback
<how to revert if the change misbehaves — exact commands or PR-revert plan>

## Verification
- [ ] <how the change was confirmed safe — smoke test, dry run, canary>
- [ ] <…>
```

---

## Worked transitions (lightweight notation)

### At creation (CREATE flow output)

```
Header: TL;DR filled, Resolution=_(to be filled at close)_
Context: filled (Background + What's happening + Why it matters, 1–2 sentences each)
Type sections: filled as much as the author knows; empty stubs OK
Verification/Acceptance: empty checkboxes OK
Links: any related items (optional)
Linear fields: Status=Backlog, Type, Owner, Project set via API
```

### When work starts (UPDATE flow)

```
Linear state field set to In Progress
(description unchanged)
```

### At close (CLOSE flow output)

```
Resolution: filled (1–3 sentences)
Verification/Acceptance: every box has [x] and a one-line evidence note
Links: any related issues touched (optional)
TL;DR: UNCHANGED
Context: UNCHANGED (unless the original framing was wrong — rare)
Linear state field set to Done; PR linked via GitHub integration
```

---

## Quick reference — section choice by type

| Section | Bug | Feature | Research | Infra |
|---------|:---:|:-------:|:--------:|:-----:|
| Context | ✓ | ✓ | ✓ | ✓ |
| Repro | ✓ | | | |
| Root cause | ✓ | | | |
| Fix | ✓ | | | |
| Scope | | ✓ | | |
| Implementation | | ✓ | | |
| Out of scope | | ✓ | | |
| Analysis goals | | | ✓ | |
| Methods | | | ✓ | |
| Deliverables | | | ✓ | |
| Change | | | | ✓ |
| Blast radius | | | | ✓ |
| Rollback | | | | ✓ |
| Verification | ✓ | | | ✓ |
| Acceptance | | ✓ | ✓ | |
| Links | ✓ | ✓ | ✓ | ✓ |

If you find yourself wanting a section that isn't in the type's row, ask: is
the issue actually a different type? The mismatch is usually a typing signal.
