---
name: jj-todo-workflow
description: Structured TODO commit workflow using JJ (Jujutsu). Use when planning tasks as empty commits with [task:*] flags, tracking progress through status transitions, managing parallel task DAGs with dependency checking, or AI-assisted development workflows. Enforces completion discipline. Requires the working-with-jj skill.
---

# JJ TODO Workflow

Use empty revisions as TODO markers to enable structured development with clear milestones. Descriptions (i.e. commit messages) act as specifications for what to implement.

**For more info on JJ basics, see the `working-with-jj` skill. We reuse scripts from that skill here.**

## Quick Start

Here's a complete cycle from planning to completion (**full paths to helper scripts not written**):

```bash
# 1. Plan: Create a simple TODO chain
jj-todo-create @ "Add user validation" "Check email format and password strength"
# Created: abc123 (stays on current @)

jj-todo-create abc123 "Add validation tests" "Test valid/invalid emails and passwords"
# Created: def456 (@ still hasn't moved)

# 2. Start working on first TODO
jj edit abc123
jj-flag-update @ wip   # Now [task:wip]

# ... implement validation ...

# 3. Verify ALL acceptance criteria met
make test  # Or equivalent in your project

# 4. Ask to move to next task
jj-todo-next
### ... review current specs (to ensure compliance) and next possible TODOs ...

# 4. Once we're sure everything is properly done, move to next TODO
jj-todo-next --mark-as done def456   # Marks abc123 as [task:done], starts def456 as [task:wip]
```

**That's it!** Empty commits as specs, edit to work on them, `jj-todo-next --mark-as done <next-step>` when FULLY complete.

## Status Flags

We use description prefixes to track status at a glance. The `[task:*]` namespace makes them greppable and avoids conflicts with other conventions.

| Flag | Meaning |
|------|---------|
| `[task:todo]` | Not started, empty revision |
| `[task:wip]` | Work in progress |
| `[task:untested]` | Implementation done, tests missing |
| `[task:broken]` | Tests failing, needs fixing |
| `[task:review]` | Needs review (tricky code, design choice) |
| `[task:blocked]` | Waiting on external dependency |
| `[task:done]` | Complete, all acceptance criteria met |

### Updating Flags

```bash
jj-flag-update @ wip
jj-flag-update @ untested
jj-flag-update @ done
```

### Finding Flagged Revisions

```bash
jj-find-flagged                     # All tasks
jj-find-flagged todo                # Only [task:todo]
jj-find-flagged wip                 # Only [task:wip]
jj-find-flagged done                # Only [task:done]

# Manual - all tasks
jj log -r 'description(substring:"[task:")'

# Incomplete tasks only
jj log -r 'description(substring:"[task:") & ~description(substring:"[task:done]")'
```

## Basic Workflow

### 1. Plan: Create TODO Chain

```bash
# Create linear chain of tasks
jj-todo-create @ "Task 1: Setup data model" "...details..."
jj-todo-create <T1-id> "Task 2: Implement core logic" "..."
jj-todo-create <T2-id> "Task 3: Add API endpoints" "..."
jj-todo-create <T3-id> "Task 4: Write tests" "..."
```

### 2. Work: Edit Each TODO

```bash
# Read the specs
jj-show-desc <task-id>    # BEWARE: Script from the `working-with-jj` skill
 
# Start working on it
jj edit <task-id>
jj-flag-update @ wip

# ... implement ...

# Mark progress
jj-flag-update @ untested
```

### 3. Complete and Move to Next

`jj-todo-next` script is there to smooth out the "transition to next task" process.

#### Without args
- Print out current task's description so you can review and make sure everything is implemented as planned
- Print out next possible task(s)

```bash
# Review current specs and see what's next
jj-todo-next
# Shows:
#   📋 Current task specs for review:
#   ─────────────────────
#   ...
#   ─────────────────────
#
#   Current task status: [task:wip]
#   Mark as [task:done] only if FULLY COMPLIANT with specs above.
#
#   ✅ Available next tasks:
#     abc123  [task:todo] Feature B
#     def456  [task:todo] Feature C
#
#   ⚠️ Child tasks with unmet dependencies:
#     xyz789  [task:todo] Integration
#             Blocked by: abc123
```

#### With args
- Update the flag of current task
- Move (`jj edit`) to the next task
- Update new task's flag to `[task:wip]`

```bash
# Actually mark current done and start editing next:
jj-todo-next --mark-as done abc123
# Does the `jj edit abc123` and shows its description
```

## Planning Parallel Tasks (DAG)

Create branches that can be worked independently. Example:

```bash
# Linear foundation
jj-todo-create @ "Task 1: Core infrastructure"
jj-todo-create <T1-id> "Task 2: Base components"

# Parallel branches from Task 2
jj-parallel-todos <T2-id> "Widget A" "Widget B" "Widget C"

# ... edit their descriptions to add more details ...

# Merge point (all three parents must complete first)
jj new --no-edit <A-id> <B-id> <C-id> -m "[task:todo] Integration of widgets\n\n..."
```

**Result:**
```
          Integration
       /      |        \
   Widget A  Widget B  Widget C
       \      |        /
          Task 2: Base
              |
          Task 1: Core
```

No rebasing needed - parents specified directly!

## Writing Good TODO Descriptions

### Structure

```
Short title (< 50 chars)

## Context
Why this task exists, what problem it solves.

## Requirements
- Specific requirement 1
- Specific requirement 2

## Implementation notes
Any hints, constraints, or approaches to consider.

## Acceptance criteria
How to know when this is FULLY DONE (not just "good enough"):
- Criterion 1
- Criterion 2
```

**Important:** Acceptance criteria define when you can mark as `[task:done]`. Be specific and testable.

**The description should overall be as self-sufficient as possible**.
It should provide an agent with little context to have every information needed to start working without having to take last-minute decisions that should have been specified before.

Avoid redundancy by linking whenever possible to:
- pre-existing spec documents
- relevant examples in the codebase

When including such links, **avoid unstable references like line numbers** which can become invalid with simple reformattings.
Prefer e.g. section names, or label refs if linking to a spec in a format that supports them (like Markdown `#stuff`, LaTeX `\ref{stuff}` or Typst `@stuff`), or function/class names when referring to code.

### Example

```
Implement user authentication

## Context
Users need to log in to access their data. Using JWT tokens
for stateless auth.

## Requirements
- POST /auth/login accepts email + password
- Returns JWT token valid for 24h
- POST /auth/refresh extends token
- Invalid credentials return 401

## Implementation notes
- Use bcrypt for password hashing (see src/auth/admin.py::AdminLogin::hash_passwd which already uses it)
- Store refresh tokens in Redis
- See auth.md (#about-tokens) for token format spec

## Acceptance criteria
- All auth endpoints return correct status codes
- Tokens expire correctly
- Rate limiting prevents brute force
```

## Documenting Implementation Deviations

When implementation differs from specs, DOCUMENT IT and JUSTIFY IT:

```bash
# After implementing, add notes
jj desc -r @ -m "$(jj-show-desc @)

## Post-Implementation notes
- Used argon2 instead of bcrypt. That's because contrary to admin case, here we also needed to comply with...
- Added /auth/logout endpoint. Not in original spec but necessary because...
- Set Rate limit to 5 attempts per minute. Was unspecified, had to make a choice.
"
```

This creates an audit trail of decisions.

## When to Stop and Report

**Follow the prescribed workflow only.**
If you encounter any issues, STOP and report to the user, notably if:
- Made changes in wrong revision
- Need to undo or modify previous work
- Uncertain about how to proceed
- Dependencies or requirements unclear

**DO NOT attempt to fix issues using any JJ operation not explicitly present in this workflow.**
Let the user handle recovery operations. Your job is to follow the process or report when you can't.

## AI-Assisted TODO Workflow

TODOs work great with AI assistants:

- Human or Supervisor Agent does the initial planning and creates the graph of TODO revisions
- Worker Agent(s) just "run" through the graph, following the structure and requirements, implementing each revision **sequentially**
- Human or Supervisor Agent can review the diffs and notes, and switch back tasks to e.g. `[todo:wip]` when necessary

**IMPORTANT: Worker agents MUST work sequentially through tasks, not in parallel.**
Running multiple agents concurrently on the same repository causes conflicts as they fight over the working copy (`@`).

If parallel work is truly needed, you must use JJ workspaces (equivalent to git worktrees) to isolate each agent.
However, **do not create workspaces** unless the human user explicitly agrees to it, as it adds significant complexity.

See `references/parallel-agents.md` for detailed guide on using workspaces for parallel execution.

## Tips

### Keep TODOs Small

Each TODO should be completable in one focused session. If it's too big, split into multiple TODOs.

### Use `--no-edit` Religiously

When creating TODOs, always use `jj-todo-create` or `jj new --no-edit`.
**Otherwise @ moves and you lose your place.**

### Completion Discipline: No "Good Enough"

**Do NOT mark a task as done unless ALL acceptance criteria are met.**

✅ **Mark as done when:**
- Every requirement implemented
- All acceptance criteria pass
- Tests pass (if applicable)
- No known issues remain

❌ **Never mark as done when:**
- "Good enough" or "mostly works"
- Tests failing
- Partial implementation
- Workarounds instead of proper fixes
- Planning to "come back to it later"

**If incomplete:**
- Use `--mark-as review` if needs feedback
- Use `--mark-as blocked` if waiting on external dependency
- Use `--mark-as untested` if some parts could not be tested for some reason
- Stay on `[task:wip]` and keep working

```bash
# FIRST: Verify the work
make check        # or: cargo build, pnpm tsc, uv run pytest

# ONLY if all checks pass:
jj-todo-next --mark-as done <next-id>
```

### Check Dependencies Before Starting

When working with parallel branches or complex DAGs:

```bash
# Check what a task depends on (its ancestors)
jj log -r '::<rev-id>'

# Check what depends on a task (its descendants)
jj log -r '<rev-id>::'
```

**Note:** `jj-todo-next` checks dependencies automatically to indicate which children tasks aren't ready, but it's just here to smooth things out, not to abstract from `jj`. Inspect the graph yourself with `jj log` whenever needed.

## Helper Scripts

Helper scripts in `scripts/`. Invoke with full path to avoid PATH setup.

| Script | Purpose |
| ------ | ------- |
| `jj-todo-create <PARENT> <TITLE> [DESC]` | Create TODO (stays on @) |
| `jj-parallel-todos <PARENT> <T1> <T2>...` | Create parallel TODOs |
| `jj-todo-next [--mark-as STATUS] [REV]` | Review specs, check dependencies, mark & optionally move |
| `jj-flag-update <REV> <TO_FLAG>` | Update status flag (auto-detects current) |
| `jj-find-flagged [FLAG]` | Find flagged revisions |

**Additional useful scripts from the `working-with-jj` skill:**

| Script | Purpose |
| ------ | ------- |
| `jj-show-desc [REV]` | Get description of a revision |

## References

Advanced topics and detailed guides:

- `references/parallel-agents.md` - Using JJ workspaces for parallel agent execution
