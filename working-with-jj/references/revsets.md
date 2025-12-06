# Revsets Reference

Revsets are JJ's query language for selecting revisions.

```bash
jj help -k revsets    # Official documentation
```

## Basic Selectors

```bash
@                     # Working copy
@-                    # Parent(s) of @
@--                   # Grandparent(s)
root()                # Root commit (empty ancestor)
<change-id>           # By change ID (e.g., abc, xyzmno)
<commit-id>           # By commit hash
visible()             # All visible revisions (built-in alias)
hidden()              # All hidden revisions (built-in alias)
```

**Note (v0.32+):** Bare symbols no longer resolve to multiple revisions.
Use explicit functions for prefix queries:

```bash
change_id(abc)        # Match change IDs starting with 'abc'
commit_id(abc)        # Match commit IDs starting with 'abc'
bookmarks(exact:name) # Match bookmark by exact name
```

## Ancestry Operators

```bash
::@                   # All ancestors of @ (inclusive)
@::                   # All descendants of @ (inclusive)
@-::                  # Descendants of parent (siblings and their children)
<from>::<to>          # Range from..to (inclusive both ends)

# Exclusive variants
@-                    # Immediate parents only
@+                    # Immediate children only

# Depth-limited queries (v0.31+)
ancestors(@, 3)       # Ancestors up to depth 3 (parents + grandparents + great-grandparents)
descendants(@, 2)     # Descendants up to depth 2 (children + grandchildren)
parents(@, 2)         # Parents at EXACTLY depth 2 (grandparents only)
children(@, 2)        # Children at EXACTLY depth 2 (grandchildren only)
first_parent(@)       # First parent only (useful for merge commits)
first_ancestors(@)    # Ancestors via first parent chain only
```

## Filter Functions

```bash
mine()                          # Your changes (by author)
heads(all())                    # All head revisions (no children)
roots(<revset>)                 # Roots of given revset
empty()                         # Empty revisions (no diff)
conflicted()                    # Revisions with unresolved conflicts (renamed from conflict() in v0.33)
immutable()                     # Immutable revisions (usually main, tags)
mutable()                       # Mutable revisions
signed()                        # Cryptographically signed commits

# Text matching
description(substring:"text")   # Match anywhere in description
description(exact:"text")       # Exact description match
subject(substring:"text")       # Match first line only
author(substring:"name")        # Match author name/email
committer(substring:"name")     # Match committer

# Specific field matching (v0.26+)
author_name(substring:"name")   # Match author name only
author_email(glob:"*@example.com") # Match author email
committer_name(substring:"name")   # Match committer name
committer_email(glob:"*@corp.com") # Match committer email

# File-based
files("path/to/file")            # Revisions that modified this file
files(glob:"src/*.rs")           # Glob pattern matching

# Validation & debugging
exactly(revset, N)              # Assert revset has exactly N elements (errors otherwise)
bisect(revset)                  # For binary search debugging
fork_point(revset)              # Common ancestor for rebasing
```

## Set Operations

```bash
A | B                 # Union: revisions in A OR B
A & B                 # Intersection: revisions in A AND B
A ~ B                 # Difference: revisions in A but NOT in B
~A                    # Complement: all revisions NOT in A
```

## Useful Patterns

### Working with branches

```bash
# Your work on current line
mine() & ::@

# What's on this branch but not in main
::@ ~ ::main

# Heads of your work (tips)
heads(mine())

# All your unmerged work
mine() ~ ::main
```

### Finding specific changes

```bash
# Changes to a specific file
files("src/lib.rs")

# Your changes to src/ directory
files("src/") & mine()

# Empty commits whose description contains "[todo]"
empty() & description(substring:"[todo]")

# Commits with conflicts
conflict()
```

### Navigation

```bash
# Recent commits (last 10 by default in log)
@ | @- | @-- | @---

# All siblings (same parent as @)
@-+ ~ @

# Common ancestor of two revisions
heads(::A & ::B)
```

### Remote tracking

```bash
# Remote main
main@origin

# What's in remote but not local
::main@origin ~ ::main

# What's local but not pushed
::main ~ ::main@origin
```

## Quoting in Shell

Revsets with special characters need shell quoting:

```bash
# ❌ Shell interprets parentheses and quotes
jj log -r description(substring:"[todo]")

# ✅ Single quotes protect everything
jj log -r 'description(substring:"[todo]")'

# ✅ Double quotes with escaping
jj log -r "description(substring:\"[todo]\")"

# ✅ Simple revsets don't need quotes
jj log -r mine
jj log -r @-
```

**Rule:** When in doubt, wrap the entire revset in single quotes.
