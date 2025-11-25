# Templates Reference

Templates control JJ's output formatting.

```bash
jj help -k templates    # Official documentation
```

## Built-in Templates

```bash
# For jj log
builtin_log_compact      # Default compact view
builtin_log_detailed     # Full details with diff
builtin_log_oneline      # Single line per revision

# For jj evolog
builtin_evolog_compact   # Default evolution log

# For jj op log
builtin_op_log_compact   # Operation log
```

## Context Separation

**Critical:** Different commands have different template contexts.

### Log Templates (revision context)

```bash
# Direct access to revision properties
change_id                    # Full change ID
change_id.short()            # Short form (default 12 chars)
change_id.shortest()         # Shortest unique prefix
commit_id                    # Git commit hash
description                  # Full description
description.first_line()     # First line only
author                       # Author info
author.name()                # Author name
author.email()               # Author email
author.timestamp()           # Author timestamp
committer                    # Committer info (same methods)
empty                        # Boolean: is empty?
conflict                     # Boolean: has conflicts?
```

### Evolog Templates (commit context)

```bash
# Must go through commit object
commit.change_id()
commit.commit_id()
commit.description()
commit.author()
# etc.
```

### Op Log Templates (operation context)

```bash
self.id()                    # Operation ID
self.id().short(12)          # Short operation ID
self.description()           # What the operation did
self.time()                  # When it happened
self.user()                  # Who did it
```

## Template Language

### String Concatenation

```bash
# Use ++ to join strings
change_id.shortest(8) ++ " " ++ description.first_line()
```

### Conditionals

```bash
# if(condition, then, else)
if(conflict, "⚠️ ", "")
if(empty, "(empty)", description.first_line())
```

### Methods

```bash
# Strings
description.first_line()
description.lines()          # List of lines
"text".contains("x")
"text".starts_with("x")

# IDs
change_id.short()            # Default length
change_id.short(6)           # Specific length
change_id.shortest()         # Minimum unique
change_id.shortest(4)        # Minimum 4 chars

# Timestamps
timestamp.ago()              # "2 hours ago"
timestamp.format("%Y-%m-%d") # Custom format
```

### Special Output

```bash
# JSON output (for scripting)
jj log -T "json(self)"

# Diff statistics
diff.stat(72)                # Stat with max width

# Labels for coloring
label("keyword", "text")
```

## Useful Custom Templates

### Compact one-liner

```bash
jj log -T 'change_id.shortest(8) ++ " " ++ description.first_line() ++ "\n"'
```

### With status indicators

```bash
jj log -T '
  change_id.shortest(8)
  ++ if(conflict, " ⚠️", "")
  ++ if(empty, " ∅", "")
  ++ " " ++ description.first_line()
  ++ "\n"
'
```

### Files changed

```bash
jj log -T 'change_id.shortest(8) ++ "\n" ++ diff.stat(72)'
```

### For scripting (parseable)

```bash
# Tab-separated
jj log -T 'change_id.short() ++ "\t" ++ description.first_line() ++ "\n"' --no-graph

# JSON
jj log -T "json(self)" --no-graph
```

### Operation IDs for checkpoints

```bash
jj op log -T 'self.id().short(12) ++ " " ++ self.description() ++ "\n"' --no-graph -n5
```

## Config File Templates

Define reusable templates in `~/.jjconfig.toml`:

```toml
[templates]
log = 'change_id.shortest(8) ++ " " ++ description.first_line()'

[template-aliases]
'format_short_id(id)' = 'id.shortest(8)'
```

Then use with:

```bash
jj log -T log
# or reference alias in other templates
```
