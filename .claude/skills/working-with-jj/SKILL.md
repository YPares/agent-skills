---
name: working-with-jj
description: Expert guidance for using JJ (Jujutsu) version control system. Use when working with JJ, whatever the subject. Operations, revsets, templates, TODO commit workflows, debugging change evolution, etc. Covers JJ commands, template system, evolog, operations log, and specific JJ workflows.
---

# JJ (Jujutsu) Version Control Helper

Expert guidance for using JJ (Jujutsu) version control system.

## Core Principles

JJ fixes fundamental Git UX issues while maintaining compatibility:

- **Change IDs** (immutable logical changes) vs **Commit IDs** (content-based
  hashes)
- **Commits are just regular Git commits**: a revision (or "change", the two
  mean the same in JJ lingo) just points to a new commit whenever it is edited:
  the commit ID changes, the change ID stays the same
- **Operations log** provides complete safety - every operation can be undone
- **No staging area** - just working copy and commits
- **Conflicts don't block work** - can be resolved later
- **Commits are lightweight** - not "sacred artifacts"

## Common Operations

### Basic Workflow

TERMINOLOGY NOTE: "Commit messages" are usually called _"revision descriptions"_ instead in JJ.

```bash
# View revision history
jj log -r <revset> -T builtin_log_compact
# (the user may have a set a custom log template. builtin_log_compact is the default JJ log template)

# View detailed information about one specific revision (incl. git diff)
jj log -n1 --no-graph -r <revision> -T builtin_log_detailed --git

# Show evolution of a specific change
jj evolog -r <revision> --git

# Create new empty change and edit it
jj new <base>

# Create new empty change WITHOUT editing it (staying on current change)
jj new --no-edit <base>

# Change revision description
jj desc -r <revision> -m "Description"
# ...or feed description to set from stdin
cmd_that_outputs_description | jj desc -r <revision> --stdin
```

### TODO Commit Workflow

Empty revisions as TODO markers, with descriptions that act as specification
of what should be implemented as part of each revisions, enable structured
development with clear milestones.

#### Basic TODO Workflow

```bash
# Create empty TODO commit on specified parent(s)
jj new --no-edit <parent> -m "[todo] implement feature X\n\n<thorough description of what do to at this step>"
# Current working copy stays unchanged because of --no-edit, new revision is created ahead of parent(s)

# Work through TODOs by editing each revision:

## Read the revision description to know what exactly should be done 
jj log -r <todo-revision> -n1 --no-graph -T description
## Start editing the revision
jj edit <todo-revision>

# Update status flags as work progresses (using sed pipeline)
jj log -r @ -n1 --no-graph -T description | sed 's/\[todo\]/[wip]/' | jj desc -r @ --stdin
jj log -r @ -n1 --no-graph -T description | sed 's/\[wip\]/[untested]/' | jj desc -r @ --stdin
jj log -r @ -n1 --no-graph -T description | sed 's/\[untested\]//' | jj desc -r @ --stdin

# EVERYTHING IN THE IMPLEMENTATION THAT DIFFERS FROM THE SPECS (STATED IN THE
# REVISION DESCRIPTION) MUST BE MADE EXPLICIT AS AN "IMPLEMENTATION" ADDENDUM AT THE END
# OF THE REVISION DESCRIPTION. Edit the description to do so.
```

**Key insight:** `jj new` creates revisions on specified parents directly, no
rebase needed.

#### Status Flags Convention

Use commit message prefixes to track task status at a glance:

- **`[todo]`** - Not started, empty revision ready to be filled
- **`[wip]`** - Work in progress, incomplete implementation
- **`[untested]`** - Implementation done but tests missing or incomplete
- **`[broken]`** - Tests failing, needs fixing
- **`[review]`** - Complete but needs review (tricky code, design choice, etc.)
- **No flag** - Complete, tested, and approved

**Updating flags (recommended approach):**

```bash
# Get current description, modify, pipe back with --stdin
jj log -r <change-id> -n1 --no-graph -T description | sed 's/\[todo\]/[wip]/' | jj desc -r <change-id> --stdin

# Common transitions
[todo] → [wip]:      sed 's/\[todo\]/[wip]/'
[wip] → [untested]:  sed 's/\[wip\]/[untested]/'
[wip] → [review]:    sed 's/\[wip\]/[review]/'
[untested] → done:   sed 's/\[untested\] //'
[broken] → done:     sed 's/\[broken\] //'
[review] → done:     sed 's/\[review\] //'
```

**Finding incomplete work:**

```bash
# All flagged revisions
jj log -r 'description(glob:"[*")'

# Specific status
jj log -r 'description(glob:"[wip]*")'
jj log -r 'description(glob:"[broken]*")'
jj log -r 'description(glob:"[review]*")'
```

**Use cases for `[review]`:**

- Tricky implementation that needs a second look
- Design choice that requires discussion
- Code working but architecture debatable
- Performance concerns to validate
- Security-sensitive code

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

**Result:** Task 3 branches into 3 parallel tasks, which merge into Task 5. No
rebasing needed!

#### Rebase Operations

Only needed to fix mistakes or reorganize after the fact:

- `jj rebase -s <source> -d <dest>`: Rebase source AND descendants onto dest
- `jj rebase -r <revset> -d <dest>`: Rebase ONLY matching revisions (doesn't
  move descendants)

**Common fix pattern:** Created TODOs on wrong parent

```bash
# Accidentally created B on @ instead of A
jj new @ -m "[todo] A"
jj new @ -m "[todo] B"  # Oops, wanted B to depend on A

# Fix: rebase B onto A
jj rebase -s <B-change-id> -d <A-change-id>
```

### Template System

**Important context separation:**

- **Log templates**: Use `change_id`, `commit_id` (operating on revision object)
- **Evolog templates**: Use `commit.change_id()`, `commit.commit_id()`
  (operating on commit object)

Built-in templates:

- `builtin_log_compact`, `builtin_log_detailed` for log
- `builtin_evolog_compact` for evolog

JSON output for tooling:

```bash
# Get structured revision data
jj log -T "json(self)"

# Get commit context in evolog
jj evolog -T "commit.change_id().shortest(8)"
```

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

- **Auto-snapshotting with `watchman`:**
  - Every edit (human or AI) preserved in evolog
  - Perfect audit trail of all changes
  - Instant rollback capability - let AI experiment safely
- **Empty TODO commits:**
  - Structure AI tasks with clear milestones
  - AI can work through structured development plan
- **JSON output:**
  - Robust tooling integration
  - Parse history programmatically
- **Extensive revsets:**
  - Powerful history queries
  - Precise change selection

## Common Pitfalls & Solutions

### 1. Command Syntax Confusion

**Problem:** `-r` vs `--revisions` inconsistency
```bash
jj log -r xyz          # ✅ Correct (short form)
jj log --revisions xyz # ❌ Error: unexpected argument
jj desc -r xyz         # ✅ Correct
jj desc --revisions xyz # ❌ Error: doesn't exist
```

**Solution:** Always use short form `-r` for consistency. See `references/command-syntax.md` for details.

### 2. Batch Operations on Multiple Revisions

**Problem:** Updating descriptions for multiple revisions
```bash
# ❌ Bash syntax errors with complex pipes
for rev in a b c; do jj log -r $rev | sed 's/old/new/' | jj desc -r $rev --stdin; done

# ✅ Correct: Quote variables, separate commands properly
for rev in a b c; do
  jj log -r "$rev" -n1 --no-graph -T description | \
    sed 's/old/new/' > /tmp/desc_${rev}.txt
  jj desc -r "$rev" --stdin < /tmp/desc_${rev}.txt
done
```

**Best practice:** Use intermediate files for complex transformations. See `references/batch-operations.md`.

### 3. Creating Parallel TODO Branches

**Common mistake:** Forgetting that `jj new` without `--no-edit` moves your working copy
```bash
# ❌ Each jj new moves @, creates tangled dependencies
jj new parent -m "[todo] Task A"
jj new parent -m "[todo] Task B"  # B is now child of A, not parent!

# ✅ Use --no-edit to keep @ stable
jj new --no-edit parent -m "[todo] Task A"
jj new --no-edit parent -m "[todo] Task B"  # Both are children of parent
```

**Key insight:** `--no-edit` is essential for creating parallel branches. Your working copy (@) stays put.

### 4. Revset Quoting in Shell

**Problem:** Special characters in revsets need proper quoting
```bash
# ❌ Shell interprets glob pattern
jj log -r description(glob:"[todo]*")  # Shell error

# ✅ Proper quoting
jj log -r 'description(glob:"[todo]*")'
jj log -r "description(glob:\"[todo]*\")"
```

## Troubleshooting

### Template Issues

- Use `jj help -k templates` for comprehensive documentation
- Remember context separation: log vs evolog template syntax differs
- Test templates with `jj log -T "your_template" -r @` on current revision

### Operation Recovery

If something goes wrong:

```bash
jj op log              # Find the operation before the problem
jj op restore <op-id>  # Restore to specific operation
```

Operation IDs look just like Git commit IDs.

### Getting Help

```bash
jj help -k <keyword>   # Search help by keyword
jj <command> --help    # Command-specific help
```

## Best Practices

- **Use TODO commits** for multi-step tasks
- **Leverage JSON output** for any scripting/tooling needs
- **Don't fear experimentation** - operations log has your back
- **Use precise revsets** instead of branch names when possible
- **Keep revision descriptions clear** - they're easy to amend in JJ
