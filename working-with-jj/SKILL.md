---
name: working-with-jj
description: Expert guidance for using JJ (Jujutsu) version control system. Use when working with JJ, whatever the subject. Operations, revsets, templates, TODO commit workflows, debugging change evolution, etc. Covers JJ commands, template system, evolog, operations log, and specific JJ workflows.
---

# JJ (Jujutsu) Version Control Helper

## Core Principles

- **Change IDs** (immutable) vs **Commit IDs** (content-based hashes that change
  on edit)
- **Operations log** - every operation can be undone with `jj op restore`
- **No staging area** - working copy auto-snapshots
- **Conflicts don't block** - resolve later
- **Commits are lightweight** - edit freely

## Essential Commands

```bash
jj log -r <revset>                    # View history
jj evolog -r <rev> --git              # Change evolution (with diffs)
jj new <base>                         # Create revision and edit it
jj new --no-edit <base>               # Create without switching (for TODOs)
jj edit <rev>                         # Switch to editing revision
jj desc -r <rev> -m "text"            # Set description

jj diff                               # Changes in @
jj diff -r <rev>                      # Changes in revision
jj restore <path>                     # Discard changes to file
jj restore --from <rev> <path>        # Restore from another revision

jj split -r <rev>                     # Split into multiple commits
jj squash                             # Squash @ into parent
jj squash --into <dest>               # Squash @ into specific revision
jj absorb                             # Auto-squash into right ancestors

jj rebase -s <src> -d <dest>          # Rebase with descendants
jj rebase -r <rev> -d <dest>          # Rebase single revision only
```

## Quick Revset Reference

```bash
@, @-, @--                            # Working copy, parent, grandparent
::@                                   # Ancestors
mine()                                # Your changes
conflict()                            # Has conflicts
description(substring:"text")         # Match description
A | B, A & B, A ~ B                   # Union, intersection, difference
```

See `references/revsets.md` for comprehensive revset patterns.

## Common Pitfalls

### 1. Use `-r` not `--revisions`

```bash
jj log -r xyz          # ✅
jj log --revisions xyz # ❌
```

### 2. Use `--no-edit` for parallel branches

```bash
jj new parent -m "A"; jj new parent -m "B"           # ❌ B is child of A!
jj new --no-edit parent -m "A"; jj new --no-edit parent -m "B"  # ✅ Both children of parent
```

### 3. Quote revsets in shell

```bash
jj log -r 'description(substring:"[todo]")'    # ✅
```

## Scripts

Helper scripts in `scripts/`. Add to PATH or invoke directly.

| Script                                    | Purpose                                |
| ----------------------------------------- | -------------------------------------- |
| `jj-show-desc [REV]`                      | Get description only                   |
| `jj-show-detailed [REV]`                  | Detailed info with git diff            |
| `jj-todo-create <PARENT> <TITLE> [DESC]`  | Create TODO (stays on @)               |
| `jj-todo-done [NEXT_REV]`                 | Complete current TODO, start next      |
| `jj-flag-update <REV> <TO_FLAG>`          | Update status flag (auto-detects current) |
| `jj-find-flagged [FLAG]`                  | Find flagged revisions                 |
| `jj-parallel-todos <PARENT> <T1> <T2>...` | Create parallel TODOs                  |
| `jj-desc-transform <REV> <CMD...>`        | Pipe description through command       |
| `jj-batch-desc <SED_FILE> <REV...>`       | Batch transform descriptions           |
| `jj-checkpoint [NAME]`                    | Record op ID before risky operations   |

These scripts are notably useful if you are working using a _"TODO Commit
Workflow"_: see `references/todo-workflow.md` for structured TODO planning,
parallel task DAGs, and AI-assisted workflows.

## Recovery

```bash
jj op log              # Find operation before problem
jj op restore <op-id>  # Restore to that state
```

## References

- `references/todo-workflow.md` - Structured TODO planning, parallel DAGs, AI
  workflows
- `references/revsets.md` - Full revset syntax and patterns
- `references/templates.md` - Template language and custom output
- `references/git-remotes.md` - Bookmarks, push/fetch, remote workflows
- `references/command-syntax.md` - Command flag details
- `references/batch-operations.md` - Complex batch transformations
