---
name: linear-issues
description: "Create, update, comment on, or close Linear issues in the house style: TL;DR/Resolution header + type-specific bug/feature/research/infra sections. Drafts from git/PR context, files via Linear MCP after approval. Triggers: create linear issue, file a linear ticket or bug, draft/update/close ENG-NNNN, write the resolution for, log a research task, log an infra change, comment on a linear issue."
---

# linear-issues — Linear Issue Authoring

You are an expert on writing well-structured Linear issues. This skill codifies
a consistent house template and the create / update / close lifecycle. Every
issue in the workspace (team: Engineering, prefix `ENG-`) should follow this
shape.

## HARD RULES — Read First

1. **Always use the Linear MCP** (`mcp__claude_ai_Linear__*`) to read and write issues. Never fabricate or guess issue IDs — fetch them.
2. **Every new issue follows the canonical template** in `references/template.md`. Read that file before drafting any issue body.
3. **TL;DR is the original ask, preserved forever.** Don't rewrite its meaning when the issue closes. Typo / clarity fixes are fine; semantic rewrites are not.
4. **Resolution is filled ONLY at close.** On creation, the Resolution line says `_(to be filled at close)_`.
5. **At close, two things are required:** the Resolution header line and the type-specific Verification or Acceptance section.
6. **Section policy is "lightweight at open, strict at close."** On creation, only TL;DR + Context are required; everything else is optional. On close, the skill blocks until Resolution + Verification/Acceptance are populated.
7. **Use `save_comment` for notes, never `save_issue`.** Edits to the description are reserved for changes to the durable record. Conversational updates, status callouts, and quoted-context go in comments.
8. **Type is chosen on creation and never changed.** Bug / feature / research / infra. If you genuinely picked the wrong type, close the issue and refile.

## Package Info

- **MCP server:** `mcp__claude_ai_Linear__*` (claude.ai Linear)
- **Team:** Engineering (id resolved via `mcp__claude_ai_Linear__list_teams`)
- **Prefix:** `ENG-`
- **No Python package.** No version drift to track. (This is why there's no `scripts/` dir — there is no API surface to introspect.)

## Decision Tree

```
What is the user asking?
├── "create a linear issue about X" / "file a bug" / "log a research task"
│   → CREATE flow
├── "close ENG-NNNN" / "write the resolution for ENG-NNNN"
│   → CLOSE flow (only on explicit request — a merged PR does NOT trigger close)
├── "I started work on ENG-NNNN" / "update ENG-NNNN: scope changed" / "this is blocked"
│   → UPDATE flow (status change or body patch, not close)
├── "add a note to ENG-NNNN" / "comment on ENG-NNNN"
│   → COMMENT flow (use save_comment, never edit description)
└── "what does ENG-NNNN say?" / "show me ENG-NNNN"
    → READ flow (just get_issue and report)
```

## Natural Language Mapping

| User says | Action |
|-----------|--------|
| "create a linear issue", "file a bug" | CREATE flow → ask type if unclear → draft → file |
| "log a research task for X" | CREATE flow with `type=research` pre-selected |
| "log an infra change for X" | CREATE flow with `type=infra` pre-selected |
| "PR for ENG-NNNN merged" | _Not a close trigger._ Linear's GitHub integration already moves the issue to `Merged`. Wait for an explicit close request. |
| "close ENG-NNNN", "mark ENG-NNNN done" | CLOSE flow (same) |
| "I started ENG-NNNN" | UPDATE → set Linear's state field to `In Progress` |
| "ENG-NNNN is blocked because Y" | UPDATE → set Linear's state to `Blocked`; add a comment with details |
| "add a note: X" | COMMENT flow → `save_comment(issueId, body=X)` |
| "what's the status of ENG-NNNN?" | READ → `get_issue(ENG-NNNN)` → report TL;DR, Resolution, and Linear status |

## CREATE Flow

When the user wants to file a new issue:

1. **Identify the type.** If the user didn't say, ask once:
   > "Bug, feature, research, or infra?"
   If their prompt makes it obvious (e.g. "permissions cache returns stale roles after a demote" → bug), skip the question and confirm in the draft.

2. **Identify the project.** Check in order: explicit user statement → current git remote (`git remote get-url origin`) → Linear project name match. If still ambiguous, ask.

3. **Identify the owner.** Run `git config user.email`, then `mcp__claude_ai_Linear__list_users(query=<email>)` to resolve to a Linear user. Use that user as the Linear `assignee`. If the email doesn't resolve, default the assignee to the user themselves.

4. **Gather context** appropriate to the type:
   - **Bug:** `git log -5`, `git diff`, error logs the user pasted, file paths and line numbers they mentioned.
   - **Feature:** scope statements from the user, related issues, design docs.
   - **Research:** prior art, benchmark targets, the decision to be made, reference docs.
   - **Infra:** AWS resources affected, Terraform paths, blast radius.

5. **Draft the full body** following `references/template.md`. Always fill:
   - Header line 1: `**TL;DR:** <one sentence describing the ASK, not the resolution>`
   - Header line 2: `**Resolution:** _(to be filled at close)_`
   - `---` divider
   - `## Context` — always, as three labeled lines: `**Background:**` (plain-language — name what the system/codename IS so an outsider can follow), `**What's happening:**` (the problem/ask + inline evidence), `**Why it matters:**` (impact up front). Keep each to 1–2 sentences; never a dense paragraph. See `references/style-guide.md`.
   - Type-specific sections — fill what you have, leave others as a stub heading the user can fill later
   - `## Links` — optional; include only if there are related issues, docs, or other references

6. **Show the draft inline.** Do not file silently. Format:
   > Here's the draft (type: `<type>`, project: `<name>`, assignee: `@you`):
   > ```markdown
   > <full body>
   > ```
   > Reply `go` to file it, or tell me what to change.

7. **File via MCP.** On approval, call `mcp__claude_ai_Linear__save_issue` with:
   - `team`: Engineering
   - `project`: the resolved project
   - `title`: a descriptive, action-first title (verb-led; encode the *fix* or *mechanism* not just the symptom)
   - `description`: the assembled markdown
   - `assignee`: the resolved Linear user
   - `priority`: ask if not stated (default Medium = 3)

8. **Report** the new issue ID and URL.

## CLOSE Flow

When the user explicitly asks to close an issue (e.g. "close ENG-NNNN", "write the resolution for ENG-NNNN"). A merged PR alone does NOT trigger this flow — Linear's GitHub integration handles the `Merged` status, and closing is a separate, human-decided step (a release or verification may still be pending, or the issue may span multiple PRs). The merged PR is still used as *input* to draft the Resolution once a close is requested:

1. **Fetch the issue:** `get_issue(id=ENG-NNNN)`. Read the current TL;DR, Context, and which type-specific sections exist.

2. **Fetch the PR** if one is mentioned. Use `gh pr view <num> --json title,body,mergedAt,files` to get title, body, and changed files. If the PR is in a different repo than cwd, use `gh pr view <num> --repo <owner/repo> ...`.

3. **Draft the patch:**
   - **Resolution line:** write 1–3 sentences explaining *what was done*. Match the granularity of the TL;DR. If the TL;DR is "permissions cache returns stale roles for up to 5 minutes after a demote", the Resolution should be "Added `PermissionCache.invalidate(user_id)` and called it from `RoleService.updateRole` after the DB commit; only the mutated user's key is evicted."
   - **Verification** (bug / infra) or **Acceptance** (feature / research) section: convert each line into a `- [x]` checkbox with a one-line evidence note. If the section was empty at open, create it now with the actual verification steps the PR shipped.
   - **Links** section (optional): add any related issues touched. The PR itself should already be linked via Linear's GitHub integration (branch name containing the issue ID, or "Closes ENG-NNNN" in the PR description) — don't duplicate it in the body.

4. **Show the patch as a diff.** Highlight: the new Resolution text, the new/updated Verification checklist, and any new Links entries.

5. **Apply on approval.** Update:
   - `save_issue(id=ENG-NNNN, description=<new body>, state=Done)`
   - If the issue had subtasks still open, surface that — don't auto-close the parent.
   - Verify the PR is linked to the issue via Linear's GitHub integration. If not, ensure the PR description mentions "Closes ENG-NNNN".

## UPDATE Flow (not close)

For status changes or body patches that aren't a close:

1. **Status change** (Backlog → In Progress, In Progress → Blocked, etc.): update Linear's `state` field via the API.
2. **Scope edit** (user says "actually, also include X"): edit the relevant body section (Scope, Implementation, etc.). Leave TL;DR alone unless the *original ask* genuinely changed — if it did, prefer closing this issue and filing a new one rather than mutating the TL;DR.
3. **Always show the diff** before applying.

## COMMENT Flow

When the user says "add a note", "comment on ENG-NNNN", or wants to surface ephemeral context (a chat quote, a meeting decision, a "checking with the platform team first"):

- Use `mcp__claude_ai_Linear__save_comment(issueId, body=<note>)`.
- **Never edit the description for this.** The description is the durable record; comments are the conversation.
- Comments do not need to follow the template — write them as the user said them.

## READ Flow

For "what does ENG-NNNN say?" or "show me ENG-NNNN":

- `get_issue(id=ENG-NNNN)` → report the TL;DR, Resolution, and Linear's native status/assignee fields, plus the section headings. Don't dump the full body unless asked.

## When to Load Reference Files

- **Read `references/template.md`** before drafting any new issue body (CREATE flow) or filling sections at close (CLOSE flow). It has the exact section order and type-specific shapes.
- **Read `references/examples.md`** when the user's prompt is ambiguous about which type fits, or when you need to mirror the granularity of a real issue. It has 4 worked issues (ENG-412 bug, ENG-377 feature, ENG-419 research, ENG-405 infra) shown in both Open and Done states.
- **Read `references/style-guide.md`** for: how to write a 1-sentence TL;DR, when to use Context vs Repro vs Methods, what NOT to put in the description, title conventions, and Owner-resolution rules.

Load only what's relevant to the current flow. Don't preemptively load all three.

## Common Mistakes to Avoid

- **Rewriting the TL;DR at close.** The TL;DR preserves the original problem statement. The Resolution line is where the answer goes.
- **Writing the Resolution at creation.** Resolution is a close-time field. At open, it stays `_(to be filled at close)_`.
- **Using `save_issue` to add a comment.** Use `save_comment` for ephemeral context (chat quotes, decisions, notes from standup).
- **Putting `## Repro` in a non-bug issue.** Repro is bug-specific. Use Methods for research, Scope for feature, Change for infra.
- **Asking the user to fill in every field at creation.** Only TL;DR + Context are required at open. Type-specific sections are optional placeholders.
- **Filing issues silently.** Always show the draft and wait for approval before calling `save_issue` for a new issue.
- **Inferring the type from the user's role rather than the work.** An engineer filing a bug is filing a bug, not a research task. The work decides the type, not the author.
