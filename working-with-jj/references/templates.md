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
builtin_op_log_oneline   # Single line per operation
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

### Evolog Templates (CommitEvolutionEntry context, v0.33+)

```bash
# Must go through commit object (changed in v0.33)
commit.change_id()
commit.commit_id()
commit.description()
commit.author()
# etc.

# Evolution-specific methods
operation                        # Associated operation
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

# Join with separator (v0.36+)
join(sep, item1, item2, ...)  # Joins non-empty items with separator
```

### Operators

```bash
# Conditionals
if(conflict, "⚠️ ", "")
if(empty, "(empty)", description.first_line())

# Comparison (v0.25+)
x == y, x != y               # Equality (Boolean, Integer, String)
x > y, x >= y, x < y, x <= y # Relational (Integer only)

# Arithmetic (v0.30+, Integer only)
x + y, x - y, x * y, x / y, x % y
```

### String Methods

```bash
description.first_line()
description.lines()          # List of lines
"text".contains("x")
"text".starts_with("x")
"text".ends_with("x")

# Trimming (v0.27+)
"  text  ".trim()            # Remove whitespace both ends
"  text".trim_start()        # Remove leading whitespace
"text  ".trim_end()          # Remove trailing whitespace

# Splitting (v0.35+)
"a,b,c".split(",")           # Split into list
"a,b,c".split(",", 2)        # Split with limit

# Replacement (v0.34+)
"hello".replace("l", "L")    # Simple replacement
"hello".replace(r"l+", "L")  # Regex replacement with capture groups

# Serialization (v0.27+)
stringify(value)             # Convert any value to string
"text".escape_json()         # Escape for JSON output
```

### ID Methods

```bash
change_id.short()            # Default length
change_id.short(6)           # Specific length
change_id.shortest()         # Minimum unique
change_id.shortest(4)        # Minimum 4 chars
```

### Timestamp Methods

```bash
timestamp.ago()              # "2 hours ago"
timestamp.format("%Y-%m-%d") # Custom format
```

### List Methods (v0.33+)

```bash
list.any(|x| x.empty)        # True if any element matches
list.all(|x| x.signed)       # True if all elements match
list.filter(|x| condition)   # Filter elements (v0.26+)
```

### Diff Methods

```bash
diff.stat(72)                # Stat with max width
diff.files()                 # List of files changed (v0.26+)
files(diff)                  # Per-file statistics (v0.36+, DiffStats context)
```

### Special Functions

```bash
# JSON output (for scripting)
json(self)                   # Full JSON serialization (v0.31+)
jj log -T 'json(self) ++ "\n"'

# Configuration access (v0.26+)
config("ui.editor")          # Read config value

# Text formatting
label("keyword", "text")     # Labels for coloring
pad_centered(text, width)    # Center-pad text (v0.26+)
hyperlink(url, text)         # Clickable link for terminals (v0.34+)

# Truncation (v0.27+)
truncate_start(text, width)  # Truncate from start
truncate_end(text, width)    # Truncate from end
truncate_start(text, width, ellipsis="…")  # Custom ellipsis
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
jj op log -T 'id.short(12) ++ " " ++ description ++ "\n"' --no-graph -n5
```

## Config File Templates

Define reusable templates in TOML file:

```toml
[template-aliases]
'format_short_id(id)' = 'id.shortest(8)'
mylog = 'format_short_id(change_id) ++ " " ++ description.first_line()'
```

Then use with:

```bash
jj log -T mylog --config-file path/to/config.toml
# or reference alias in other templates
```
