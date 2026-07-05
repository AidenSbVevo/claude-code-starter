# How We Work

*Project management with Linear — and how Claude Code participates in it.*

## Why this exists

Software is built by more than one person, and increasingly by more than one
*kind* of contributor: engineers and the AI agents they drive. For that to work,
everyone needs a shared, durable record of what the project is, what's been
decided, what's in flight, and who owns what. We keep that record in **Linear**.

Linear is not just a task tracker here — it's the project's **memory**, for us
*and* for Claude. A well-written issue outlives the Slack thread and the meeting
it came from. When a teammate picks up an issue, or when Claude Code opens a
session to implement one, the issue *is* the context: the goal, the constraints,
the acceptance criteria, the decisions already made. That is what lets many
people and many agent sessions collaborate on one codebase without stepping on
each other. Each unit of work is described precisely enough that anyone — human
or model — can pick it up cold and know who did what, what's done, and what's
next. Assignees and status live in Linear too, so Claude reads the same board we
do and stays aware of ownership.

## The hierarchy: Project → Epic → Issue

We organize work in three levels:

- **Project** — a coherent body of work with an outcome: a feature area, a
  subsystem, a migration. The top-level container in Linear.
- **Epic** — a series of related issues that together deliver one slice of the
  project. An epic is a plan, broken into shippable pieces.
- **Issue** — the atomic unit. Rule of thumb: **one issue ≈ one Claude Code
  session ≈ one PR.**

That last equivalence is load-bearing. An issue is sized so it can go from start
to merged PR in a single focused session and be reviewed as one coherent diff.
If a piece of work can't fit that shape, it's not an issue — it's an epic, and it
gets broken down further. Sizing to one-session-one-PR keeps diffs reviewable,
keeps context windows sane, and makes progress legible: every merged PR closes
exactly one issue.

The **`epic-planning`** skill does the breakdown — it turns a goal or feature
area into one-PR-sized issues, each with acceptance criteria and verification
commands, before any code is written.

## Structured issue bodies

An issue is only useful as memory if it's written well. We keep bodies to a
consistent **house style** so they're skimmable by humans and reliably parseable
by Claude:

- A **TL;DR / Resolution** header — the one-paragraph answer to *"what is this,
  and where does it stand."*
- **Type-specific sections** — a bug reads differently from a feature, a research
  task, or an infra change, so each type has its own structure (repro / expected
  / actual for bugs; motivation / approach / acceptance for features; and so on).

The **`linear-issues`** skill writes and updates issues in this style. It drafts
from git and PR context, fills the sections appropriate to the issue type, and
files via Linear after review. The payoff is consistency: every issue looks the
same, so any reader — human or Claude — always knows where to find the goal, the
acceptance criteria, and the current state.

## How it fits together

```
Project  (in Linear)
  └─ Epic ───────── epic-planning breaks it into one-PR-sized issues
        ├─ Issue ── one Claude Code session → one PR  (ship-issue)
        ├─ Issue ── …
        └─ Issue ── …
```

Each issue, written in house style by `linear-issues`, carries its own context.
Claude opens a session against an issue, implements it, and ships a PR that
closes it — updating the issue as it goes, so the project's memory stays current
for whoever, or whatever, works next.
