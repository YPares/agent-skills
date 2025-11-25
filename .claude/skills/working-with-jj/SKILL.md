---
name: working-with-jj
description: Expert guidance for using JJ (Jujutsu) version control system. Use when working with JJ, whatever the subject. Operations, revsets, templates, TODO commit workflows, debugging change evolution, etc. Covers JJ commands, template system, evolog, operations log, and specific JJ workflows.
---

# JJ (Jujutsu) Version Control Helper

## Core Principles

JJ fixes fundamental Git UX issues while maintaining compatibility:

- **Change IDs** (immutable logical changes) vs **Commit IDs** (content-based hashes)
- **Commits are just regular Git commits**: a revision (or "change") just points to a new commit whenever it is edited: the commit ID changes, the change ID stays the same
- **Operations log** provides complete safety - every operation can be undone
- **No staging area** - just working copy and commits
- **Conflicts don't block work** - can be resolved later
- **Commits are lightweight** - not "sacred artifacts"

## Scripts

Helper scripts in `scripts/` directory handle common operations. Add to PATH or invoke directly.

### Viewing Revisions

```bash
jj-show-desc [REV]         # Get description only (default: @)
jj-show-detailed [REV]     # Detailed info with git diff
```

### TODO Workflow

```bash
jj-todo-create <PARENT> <TITLE> [DESCRIPTION]   # Create TODO revision (stays on @)
jj-flag-update <REV> <FROM> <TO>                # Update status flag
jj-find-flagged [FLAG]                          # Find flagged revisions
jj-parallel-todos <PARENT> <T1> <T2>...         # Create parallel TODOs
```

**Status flags:** `todo` → `wip` → `untested` → (done). Also: `broken`, `review`

### Description Transformations

```bash
jj-desc-transform <REV> <CMD...>        # Pipe description through command
jj-batch-desc <SED_FILE> <REV1>...      # Apply sed script to multiple revisions
```

**Examples:**

```bash
# Update flag
jj-flag-update @ todo wip
jj-flag-update mxyz wip done

# Transform description
jj-desc-transform @ sed 's/old/new/'

# Batch update with sed script
cat > /tmp/fixes.sed << 'EOF'
s/foo/bar/g
s/baz/qux/g
EOF
jj-batch-desc /tmp/fixes.sed abc xyz mno
```

## Direct JJ Commands

### Basic Operations

```bash
jj log -r <revset> -T builtin_log_compact     # View history
jj evolog -r <revision> --git                 # Show change evolution
jj new <base>                                 # Create new revision (edit it)
jj new --no-edit <base>                       # Create without switching
jj desc -r <revision> -m "Description"        # Set description
jj edit <revision>                            # Switch to editing revision
```

### Rebase Operations

- `jj rebase -s <source> -d <dest>`: Rebase source AND descendants onto dest
- `jj rebase -r <revset> -d <dest>`: Rebase ONLY matching revisions (not descendants)

### Revsets

```bash
jj help -k revsets                           # Full documentation

# Examples
jj log -r "mine()"                           # Your changes
jj log -r "::@"                              # Ancestors of @
jj log -r "mine() & ::@"                     # Your changes in current branch
jj log -r 'description(substring:"[todo]")'  # Match description
```

### Template System

- **Log templates**: Use `change_id`, `commit_id`
- **Evolog templates**: Use `commit.change_id()`, `commit.commit_id()`
- Built-in: `builtin_log_compact`, `builtin_log_detailed`, `builtin_evolog_compact`
- JSON output: `jj log -T "json(self)"`

## TODO Workflow Details

### Status Flags Convention

- **`[todo]`** - Not started, empty revision
- **`[wip]`** - Work in progress
- **`[untested]`** - Implementation done, tests missing
- **`[broken]`** - Tests failing
- **`[review]`** - Needs review (tricky code, design choice)
- **No flag** - Complete

### DAG with Parallel Tasks

Create complex dependency graphs by specifying parents directly:

```bash
# Linear chain
jj-todo-create @ "Task 1: Foundation"
jj-todo-create <T1-id> "Task 2: Core"

# Parallel branches from Task 2
jj-parallel-todos <T2-id> "Widget A" "Widget B" "Widget C"

# Merge point (manually)
jj new --no-edit <A-id> <B-id> <C-id> -m "[todo] Integration"
```

No rebasing needed - parents specified directly!

## Common Pitfalls

### 1. `-r` Flag Only

Always use short form `-r`, never `--revisions` or `--revision`:

```bash
jj log -r xyz          # ✅
jj log --revisions xyz # ❌
```

### 2. `--no-edit` for Parallel Branches

Without `--no-edit`, each `jj new` moves @, creating tangled dependencies:

```bash
jj new parent -m "[todo] A"
jj new parent -m "[todo] B"  # ❌ B is child of A!

jj new --no-edit parent -m "[todo] A"
jj new --no-edit parent -m "[todo] B"  # ✅ Both children of parent
```

### 3. Shell Quoting for Revsets

```bash
jj log -r description(substring:"[todo]")      # ❌ Shell error
jj log -r 'description(substring:"[todo]")'    # ✅
```

See `references/command-syntax.md` for full syntax details.
See `references/batch-operations.md` for complex batch transformations.

## Troubleshooting

### Operation Recovery

```bash
jj op log              # Find operation before problem
jj op restore <op-id>  # Restore to that state
```

### Getting Help

```bash
jj help -k <keyword>   # Search help
jj <command> --help    # Command-specific
```

## AI-Assisted Development Integration

JJ is perfect for AI workflows:

- **Auto-snapshotting with watchman**: Every edit preserved in evolog, instant rollback
- **TODO commits**: Structure AI tasks with clear milestones
- **JSON output**: `jj log -T "json(self)"` for robust tooling
- **Extensive revsets**: Powerful history queries
