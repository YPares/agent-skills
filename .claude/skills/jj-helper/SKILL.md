---
name: jj-helper
description: Expert guidance for using JJ (Jujutsu) version control system. Use when working with JJ operations, revsets, templates, TODO commit workflows, debugging change evolution, or integrating JJ with AI-assisted development. Covers JJ commands, template system, evolog, operations log, and Yves' specific JJ workflows.
---

# JJ (Jujutsu) Version Control Helper

Expert guidance for using JJ (Jujutsu) version control system with Yves' workflows.

## Core Principles

### Mental Model
JJ fixes fundamental Git UX issues while maintaining compatibility:
- **Change IDs** (immutable logical changes) vs **Commit IDs** (content-based hashes)
- **Operations log** provides complete safety - every operation can be undone
- **No staging area** - just working copy and commits
- **Conflicts don't block work** - can be resolved later
- **Commits are lightweight** - not "sacred artifacts"

### Safety First
Every JJ operation is recorded in the operations log:
- `jj op log` - view operation history
- `jj op undo` - revert last operation
- You can experiment fearlessly with JJ

## Common Operations

### Basic Workflow
```bash
# View revision history
jj log -r <revset>

# Show evolution of a specific change
jj evolog -r <revision>

# Create new empty change and edit it
jj new <base>

# Create new empty change WITHOUT editing it (staying on current change)
jj new --no-edit <base>

# Change commit message
jj desc -r <revision> -m "Description"

# See current work with git diff
jj show --git
```

### TODO Commit Workflow

Empty commits as TODO markers enable structured development with clear milestones.

#### Basic TODO Pattern
```bash
# Create empty TODO commit on specified parent(s)
jj new --no-edit <parent> -m "[todo] implement feature X"

# Current working copy stays unchanged, new revision created ahead

# Work through TODOs by editing the revision
jj edit <todo-revision>

# Clean up abandoned TODOs
jj abandon <todo-revision>
```

**Key insight:** `jj new` always creates revisions based on specified parents, never needs rebase.

#### Advanced: DAG with Parallel Tasks

Create complex dependency graphs by specifying parents directly:

```bash
# Create linear chain by referencing previous change-id
jj new --no-edit @ -m "[todo] Task 1: Foundation"
jj new --no-edit <T1-change-id> -m "[todo] Task 2: Core"
jj new --no-edit <T2-change-id> -m "[todo] Task 3: Data model"

# Create parallel branches from same parent (Task 3)
jj new --no-edit <T3-change-id> -m "[todo] Task 4a: Widget A"
jj new --no-edit <T3-change-id> -m "[todo] Task 4b: Widget B"
jj new --no-edit <T3-change-id> -m "[todo] Task 4c: Widget C"

# Create merge point with multiple parents
jj new --no-edit <T4a-change-id> <T4b-change-id> <T4c-change-id> -m "[todo] Task 5: Integration"
```

**Result:** Task 3 branches into 3 parallel tasks, which merge into Task 5. No rebasing needed!

#### Rebase Operations

Only needed to fix mistakes or reorganize after the fact:

- `jj rebase -s <source> -d <dest>`: Rebase source AND descendants onto dest
- `jj rebase -r <revset> -d <dest>`: Rebase ONLY matching revisions (doesn't move descendants)

**Common fix pattern:** Created TODOs on wrong parent
```bash
# Accidentally created B on @ instead of A
jj new @ -m "[todo] A"
jj new @ -m "[todo] B"  # Oops, wanted B to depend on A

# Fix: rebase B onto A
jj rebase -s <B-change-id> -d <A-change-id>
```

### Template System (v0.33+)

**Important context separation:**
- **Log templates**: Use `change_id`, `commit_id` (operating on revision object)
- **Evolog templates**: Use `commit.change_id()`, `commit.commit_id()` (operating on commit object)

Built-in templates:
- `builtin_log_compact`, `builtin_log_detailed` for log
- `builtin_evolog_compact` for evolog (v0.33+)

JSON output for tooling:
```bash
# Get structured revision data
jj log -T "json(self)"

# Get commit context in evolog
jj evolog -T "commit.change_id().shortest(8)"
```

Configuration:
- `templates.log` for log command templates
- `templates.evolog` for evolog command templates (v0.33+)

### Revsets

Most JJ commands accept `-r` (`--revset`/`--revision`) to select scope:

```bash
# View comprehensive revsets documentation
jj help -k revsets

# Examples
jj log -r "mine()"                    # Your changes
jj log -r "::@"                       # Ancestors of working copy
jj log -r "mine() & ::@"              # Your changes in current branch
```

## AI-Assisted Development Integration

JJ is perfect for AI-assisted workflows:

1. **Auto-snapshotting with `watch + jj debug snapshot`:**
   - Every edit (human or AI) preserved in evolog
   - Perfect audit trail of all changes
   - Instant rollback capability - let AI experiment safely

2. **Empty TODO commits:**
   - Structure AI tasks with clear milestones
   - AI can work through structured development plan

3. **JSON output:**
   - Robust tooling integration
   - Parse history programmatically

4. **Extensive revsets:**
   - Powerful history queries
   - Precise change selection

## Version-Specific Notes

### Evolog Evolution (v0.33+)
- **Pre-0.33**: Operation metadata (`-- operation xxx`) auto-appended, breaking template parsing
- **v0.33+**: Operation metadata fully template-controlled, eliminating parsing issues

If working with pre-0.33 JJ, account for metadata in parsing logic.

## Troubleshooting

### Template Issues
- Use `jj help -k templates` for comprehensive documentation
- Remember context separation: log vs evolog template syntax differs
- Test templates with `jj log -T "your_template" -r @` on current revision

### Operation Recovery
If something goes wrong:
```bash
jj op log              # Find the operation before the problem
jj op undo             # Undo last operation
jj op restore <op-id>  # Restore to specific operation
```

### Getting Help
```bash
jj help -k <keyword>   # Search help by keyword
jj <command> --help    # Command-specific help
```

## Best Practices for Yves' Workflow

1. **Always use `jj show --git`** to see current work before committing
2. **Use TODO commits** for multi-step tasks
3. **Leverage JSON output** for any scripting/tooling needs
4. **Don't fear experimentation** - operations log has your back
5. **Use precise revsets** instead of branch names when possible
6. **Keep commit messages clear** - they're easy to amend in JJ
