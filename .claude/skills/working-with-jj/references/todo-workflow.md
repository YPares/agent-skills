# TODO Commit Workflow

Empty revisions as TODO markers enable structured development with clear milestones. Descriptions act as specifications for what to implement.

## Core Concept

```bash
# Create empty TODO (stays on current @)
jj-todo-create @ "Feature X" "Detailed specs of what to implement"

# Later, work on it
jj edit <todo-change-id>

# Update status as you progress
jj-flag-update @ todo wip
```

## Status Flags

Use description prefixes to track status at a glance:

| Flag | Meaning |
|------|---------|
| `[todo]` | Not started, empty revision |
| `[wip]` | Work in progress |
| `[untested]` | Implementation done, tests missing |
| `[broken]` | Tests failing, needs fixing |
| `[review]` | Needs review (tricky code, design choice) |
| (none) | Complete |

### Updating Flags

```bash
# Using script
jj-flag-update @ todo wip
jj-flag-update @ wip untested
jj-flag-update @ untested done      # "done" removes the flag

# Manual (what the script does)
jj log -r @ -n1 --no-graph -T description | sed 's/\[todo\]/[wip]/' | jj desc -r @ --stdin
```

### Finding Flagged Revisions

```bash
jj-find-flagged                     # All flagged
jj-find-flagged todo                # Only [todo]
jj-find-flagged wip                 # Only [wip]

# Manual
jj log -r 'description(substring:"[todo]")'
```

## Basic Workflow

### 1. Plan: Create TODO Chain

```bash
# Create linear chain of tasks
jj-todo-create @ "Task 1: Setup data model"
jj-todo-create <T1-id> "Task 2: Implement core logic"
jj-todo-create <T2-id> "Task 3: Add API endpoints"
jj-todo-create <T3-id> "Task 4: Write tests"
```

### 2. Work: Edit Each TODO

```bash
# Read the specs
jj-show-desc <task-id>

# Start working on it
jj edit <task-id>
jj-flag-update @ todo wip

# ... implement ...

# Mark progress
jj-flag-update @ wip untested
```

### 3. Complete: Remove Flag

```bash
# After testing passes
jj-flag-update @ untested done
```

## Parallel Tasks (DAG)

Create branches that can be worked independently:

```bash
# Linear foundation
jj-todo-create @ "Task 1: Core infrastructure"
jj-todo-create <T1-id> "Task 2: Base components"

# Parallel branches from Task 2
jj-parallel-todos <T2-id> "Widget A" "Widget B" "Widget C"

# Merge point (all three must complete first)
jj new --no-edit <A-id> <B-id> <C-id> -m "[todo] Integration"
```

**Result:**
```
       [todo] Integration
       /      |      \
   Widget A  Widget B  Widget C
       \      |      /
        Task 2: Base
            |
        Task 1: Core
```

No rebasing needed - parents specified directly!

## Writing Good TODO Descriptions

### Structure

```
[todo] Short title (< 50 chars)

## Context
Why this task exists, what problem it solves.

## Requirements
- Specific requirement 1
- Specific requirement 2

## Implementation notes
Any hints, constraints, or approaches to consider.

## Acceptance criteria
How to know when this is done.
```

### Example

```
[todo] Implement user authentication

## Context
Users need to log in to access their data. Using JWT tokens
for stateless auth.

## Requirements
- POST /auth/login accepts email + password
- Returns JWT token valid for 24h
- POST /auth/refresh extends token
- Invalid credentials return 401

## Implementation notes
- Use bcrypt for password hashing
- Store refresh tokens in Redis
- See auth.md for token format spec

## Acceptance criteria
- All auth endpoints return correct status codes
- Tokens expire correctly
- Rate limiting prevents brute force
```

## Documenting Implementation Deviations

When implementation differs from specs, document it:

```bash
# After implementing, add implementation notes
jj desc -r @ -m "$(jj-show-desc @)

## Implementation
- Used argon2 instead of bcrypt (more secure)
- Added /auth/logout endpoint (not in original spec)
- Rate limit: 5 attempts per minute (was unspecified)
"
```

This creates an audit trail of decisions.

## AI-Assisted TODO Workflow

TODOs work great with AI assistants:

### Setup Phase (Human)

```bash
# Human creates the plan
jj-todo-create @ "Refactor auth module" "
## Requirements
- Extract auth logic from handlers
- Create AuthService class
- Add unit tests
- Update API docs
"
```

### Execution Phase (AI)

```bash
# AI reads the task
jj-show-desc <todo-id>

# AI checkpoints before starting
jj-checkpoint "before-auth-refactor"

# AI edits the revision
jj edit <todo-id>
jj-flag-update @ todo wip

# ... AI implements ...

# AI marks complete
jj-flag-update @ wip untested
```

### Review Phase (Human)

```bash
# Human reviews what AI did
jj evolog -r <todo-id> --git

# If bad, restore checkpoint
jj op restore <checkpoint-op-id>

# If good but needs splitting
jj split -r <todo-id>
```

## Tips

### Keep TODOs Small

Each TODO should be completable in one focused session. If it's too big, split into multiple TODOs.

### Use `--no-edit` Religiously

When creating TODOs, always use `jj-todo-create` or `jj new --no-edit`. Otherwise @ moves and you lose your place.

### Validate Between Steps

After completing each TODO, run your project's validation (typecheck, lint, tests) before moving to the next:

```bash
# Complete the TODO
jj-flag-update @ wip done

# Verify (use your project's commands)
make check        # or: cargo build, pnpm tsc, go build, etc.

# Then start next TODO
jj edit <next-todo-id>
jj-flag-update @ todo wip  # or review, untested etc, depending on what could be completed
```

This catches errors early when context is fresh, rather than debugging cascading failures at the end.

### Watch for Hidden Dependencies

When planning TODOs that touch service/module layers (especially with dependency injection), dependencies between components may not be obvious until you validate. A component might require a service you're modifying or replacing.

If a later TODO fails due to missing dependencies from an earlier one, don't forget to edit the description to make clear the extra work you had to do which wasn't in the specs.

The upfront planning helps surface these, but some will only appear at validation time.

### Check DAG Before Starting

```bash
# Visualize the plan
jj log -r '<first-todo>::'
```

### Reorder if Needed

If you realize task order is wrong:

```bash
# Move Task B to be after Task C instead of Task A
jj rebase -r <B-id> -d <C-id>
```

### Abandon Obsolete TODOs

```bash
# If a TODO is no longer needed
jj abandon <todo-id>
```
