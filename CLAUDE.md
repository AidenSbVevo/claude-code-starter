# Global Claude Code Configuration

## About the User

<!-- Replace this with your own one-paragraph profile. It tells Claude who
     you are and how to pitch its answers. Example: -->

You are working with an experienced engineer who works across machine learning,
data, and software engineering, moving fluidly between research-grade
prototyping and production systems. Values rigor, directness, and working code
over explanations of the basics.

## Working Environment

- **Primary languages**: Python (primary), Bash, TypeScript/JavaScript for web;
  occasionally R, Rust, C++
- **Package managers**: `uv` (preferred for Python), conda/mamba where an
  existing environment needs it, pip; npm/pnpm for JS
- **Editors**: VS Code, Vim
- **Version control**: Git — always create meaningful, well-scoped commits
- **Compute**: frequently large datasets and GPU-accelerated workflows

## Code Standards

- **Python**: PEP 8, type hints, NumPy-format docstrings, prefer `pathlib` over
  `os.path`, manage dependencies with `uv`.
- **General**:
  - Add error handling and logging by default.
  - Always use a virtual environment (never global `pip` unless explicitly asked).
  - Write modular, testable code with clear separation of concerns.
  - Include a README and a dependency manifest for any project.
  - Prefer composition over inheritance.
  - Use dataclasses or pydantic models for structured data.

## Interaction Preferences

- Be direct and concise. Skip boilerplate explanations of basic concepts.
- When implementing, write the full working code — not pseudocode or snippets
  with "...".
- If a task is complex, outline the plan first, then implement step by step.
- Always check whether files/directories exist before overwriting.
- Run tests after implementation when possible.
- Commit working code with descriptive messages.

<!-- dev-pipeline:start -->
## Dev pipeline (personal)

Three personal skills implement my standard development flow — prefer them
over ad-hoc approaches when they match:

- **epic-planning** — goal/epic → one-PR-sized Linear issues, each with
  acceptance criteria and verification commands. Trigger: scoping, breaking
  down, or creating issues for an epic or feature area.
- **ship-issue** — Linear issue → shipped PR. Two hard gates (plan, ship),
  decorrelated reviews, mandatory retro. Trigger: starting / implementing /
  working / shipping a Linear issue.
- **cross-review** — decorrelated second-opinion review via local Codex CLI,
  read-only, on a plan or a diff. Trigger: "cross-review", "second opinion",
  "ask codex" — and invoked automatically by the other two.

Standing conventions (a repo `CLAUDE.md` overrides these where it speaks):

- **One writer:** Claude writes code; Codex reviews read-only and never
  writes. Never invoke Codex with write access.
- **Verifiers vs. critics:** iterate unboundedly against verifiers (tests,
  types, lint — loop to green), boundedly against critics (model reviews —
  cross-review's caps: 1 discovery + 1 verification + 1 exchange per
  contested finding). Surviving disagreement escalates to me at a gate.
- **Gates are real stops:** plan gate and ship gate wait for my explicit
  approval — never a banner walked past in the same turn.
- **Fresh base:** branch off, and rebase onto, freshly-fetched `origin/main`.
- **No AI attribution** in commits or PRs (no Co-Authored-By, no "Generated
  with" footers).
- **Python:** use `uv` for dependency management.
- **Scratch dirs:** `.plans/` and `.review/` are never committed.
- **Infra:** never delete or provision infrastructure yourself — specify
  what's needed and ask me.
<!-- dev-pipeline:end -->
