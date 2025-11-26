# JJ Command Syntax Reference

## The `-r` Flag Confusion

JJ commands are **inconsistent** with flag naming, which can be confusing:

### Commands Using `-r` (Most Common)

```bash
jj log -r <revset>        # ✅ Short form only
jj desc -r <revset>       # ✅ Short form only
jj show -r <revset>       # ✅ Short form only
jj rebase -r <revset>     # ✅ Short form only
jj edit -r <revset>       # ✅ Short form only (no --revision)
```

**Rule:** For most commands, use `-r` and **never** `--revisions` or `--revision`.

### Why This Matters

```bash
# ❌ Common mistake: trying long form
jj desc --revisions xyz
# Error: unexpected argument '--revisions' found

jj log --revision xyz
# Error: unexpected argument '--revision' found

# ✅ Always use short form
jj desc -r xyz
jj log -r xyz
```

## Command Patterns

### Reading Revision Info

```bash
# Get description only (for processing)
jj log -r <rev> -n1 --no-graph -T description

# Get detailed info (human-readable)
jj log -r <rev> -n1 --no-graph -T builtin_log_detailed

# Get compact one-liner
jj log -r <rev> -T 'change_id.shortest(4) ++ " " ++ description.first_line()'
```

**Key flags:**
- `-n1`: Limit to 1 revision
- `--no-graph`: No ASCII art graph
- `-T <template>`: Output template
- `-r <revset>`: Which revision(s)

### Modifying Revisions

```bash
# Change description from string
jj desc -r <rev> -m "New description"

# Change description from stdin (for scripts)
echo "New description" | jj desc -r <rev> --stdin

# Change description from file
jj desc -r <rev> --stdin < /path/to/description.txt

# Pipeline pattern
jj log -r <rev> -n1 --no-graph -T description | \
  sed 's/old/new/' | \
  jj desc -r <rev> --stdin
```

**Key insight:** `--stdin` is essential for scripted modifications.

### Creating Revisions

```bash
# Create and edit immediately (moves @)
jj new <parent> -m "Description"

# Create without editing (@ stays put) - IMPORTANT for parallel branches
jj new --no-edit <parent> -m "Description"

# Create with multiple parents (merge)
jj new --no-edit <parent1> <parent2> -m "Merge point"
```

**Critical distinction:**
- Without `--no-edit`: Your working copy (@) moves to the new revision
- With `--no-edit`: New revision created, but @ stays where it was

## Revset Syntax

### Basic Revsets

```bash
@                    # Working copy
<change-id>          # Specific revision (e.g., abc, unxn)
<commit-id>          # By commit hash
```

### Operators

```bash
<rev>::<rev>         # Range (from..to, inclusive)
<rev>..              # All descendants
..<rev>              # All ancestors

# Examples
zyxu::@              # All revisions from zyxu to current
roww::               # roww and all its descendants
::@                  # All ancestors of @
```

### Functions

```bash
description(glob:"pattern")    # Match description
description(exact:"text")      # Exact match
mine()                        # Your commits
```

### Combining

```bash
# Union (OR)
rev1 | rev2

# Intersection (AND)
rev1 & rev2

# Example: Your changes in current branch
mine() & ::@
```

## Shell Quoting

Revsets often need quoting because they contain special characters:

```bash
# ❌ Shell interprets glob
jj log -r description(glob:"[todo]*")

# ✅ Single quotes (safest)
jj log -r 'description(glob:"[todo]*")'

# ✅ Double quotes with escaping
jj log -r "description(glob:\"[todo]*\")"
```

**Rule:** When in doubt, use single quotes around revsets.

## Common Patterns

### Update Multiple Revisions

```bash
# Pattern: Extract → Transform → Apply
for rev in a b c; do
  jj log -r "$rev" -n1 --no-graph -T description > /tmp/desc.txt
  # ... transform /tmp/desc.txt ...
  jj desc -r "$rev" --stdin < /tmp/desc.txt
done
```

### Find and Update

```bash
# Find all [todo] revisions
jj log -r 'description(glob:"[todo]*")'

# Update specific one
jj log -r xyz -n1 --no-graph -T description | \
  sed 's/\[todo\]/[wip]/' | \
  jj desc -r xyz --stdin
```

### Create Parallel Branches

```bash
# All branch from same parent
parent=xyz
jj new --no-edit "$parent" -m "[todo] Branch A"
jj new --no-edit "$parent" -m "[todo] Branch B"
jj new --no-edit "$parent" -m "[todo] Branch C"
```

## Debugging

```bash
# Did my command work?
jj log -r <rev> -T 'change_id ++ " " ++ description.first_line()'

# View full description
jj log -r <rev> -n1 --no-graph -T description

# Check revision graph
jj log -r '<parent>::' -T builtin_log_compact
```

## Quick Reference Card

| Task | Command |
|------|---------|
| View description | `jj log -r <rev> -n1 --no-graph -T description` |
| Set description | `jj desc -r <rev> -m "text"` |
| Set from stdin | `jj desc -r <rev> --stdin` |
| Create (edit) | `jj new <parent> -m "text"` |
| Create (no edit) | `jj new --no-edit <parent> -m "text"` |
| Range query | `jj log -r '<from>::<to>'` |
| Find pattern | `jj log -r 'description(glob:"pat*")'` |
