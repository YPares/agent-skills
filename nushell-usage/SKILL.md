---
name: nushell-usage
description: Essential patterns, idioms, and gotchas for writing Nushell code. Use when writing Nushell scripts, functions, or working with Nushell's type system, pipelines, and data structures. Complements plugin development knowledge with practical usage patterns.
version: 0.2.0
targets:
  - nushell: ">=0.117.0"
---

# Nushell Usage Patterns

Examples target Nushell 0.117.0. Check `nu --version` before using
0.117-specific syntax: the rig's `nu` normally comes from its Nixpkgs input
and may lag behind upstream.

## Critical Distinctions

### Pipeline Input vs Parameters

**CRITICAL**: Pipeline input (`$in`) is NOT interchangeable with function parameters!

When a command transforms a primary input, prefer receiving that input through
the pipeline and declaring input/output types. Keep configuration in parameters:
this makes the command easier to compose with other pipelines.

```nu
# Positional arguments only: append-to [1 2 3] 4
def append-to [list: list, value: any]: nothing -> list {
    $list | append $value
}

# Pipeline input plus one positional argument
def append-value [value: any]: list -> list {
    append $value
}

# Usage
[1 2 3] | append-value 4  # [1 2 3 4]
# append-value [1 2 3] 4   # Error: extra positional argument
```

**This applies to closures too.**

**Why this matters**:
- The first pipeline in a command body receives the input directly. Calling a stream-aware command there can preserve streaming; reading `$in` as a value or binding the input with `let` collects it.
- Positional arguments are values, not streams. For closures, `do $fn $arg` binds a positional parameter; `$value | do $fn` supplies pipeline input instead.

### Type Signatures

```nu
# No pipeline input
def increment [x: int]: nothing -> int { $x + 1 }

# Pipeline input only
def text-length []: string -> int { str length }

# Both pipeline and parameters
def text-length-plus [x: int]: string -> int { ($in | str length) + $x }

# Generic pipeline
def passthrough []: any -> any {}
```

## Common Patterns

### Working with Lists

```nu
# Filter with index
$list | enumerate | where {|e| $e.index > 5 and $e.item.some-bool-field}

# Transform with previous state
$list | reduce --fold 0 {|item, acc| $acc + $item.value}
```

### Working with Records

```nu
# Create record
{name: "Alice", age: 30}

# Merge records (right-biased)
$rec1 | merge $rec2

# Merge many records (right-biased)
[$rec1 $rec2 $rec3 $rec4] | into record

# Update field
$rec | update name {|r| $"Dr. ($r.name)"}

# Insert field
$rec | insert active true

# Insert field based on existing fields
{x: 1, y: 2} | insert z {|r| $r.x + $r.y}

# Upsert (update or insert)
$rec | upsert count {|r| ($r.count? | default 0) + 1}

# Reject fields
$rec | reject password secret_key

# Select fields
$rec | select name age email

# Filter fields or convert selected fields without transposing (0.117+)
{a: 1, b: 2} | record where value > 1              # {b: 2}
{age: "42"} | record apply {age: {into int}}       # {age: 42}
```

### Working with Tables

```nu
# Tables are lists of records
let table = [
    {name: "Alice", age: 30}
    {name: "Bob", age: 25}
]

# Filter rows
$table | where age > 25

# Add column
$table | insert retired {|row| $row.age > 65}

# Rename column
$table | rename -c {age: years}

# Group by age; --to-table preserves integer keys in 0.117+
$table | group-by age --to-table

# Transpose (rows ↔ columns)
$table | transpose name data
```

### Conditional Execution

```nu
# If expressions return values
let result = if $condition {
    "yes"
} else {
    "no"
}

# Match expressions
let result = match $value {
    0 => "zero"
    1..10 => "small"
    _ => "large"
}
```

### Null Safety

```nu
# Optional fields with ?
$record.field?                    # Returns null if missing
$record.field? | default "N/A"    # Provide fallback

# Distinguish an absent field from a present null
"field" in ($record | columns)

# Optional and dynamic cell paths (spread in 0.117+)
$record | get --optional field
let paths = [name age]
$record | get ...$paths           # Returns one value per path
```

### Error Handling

```nu
# Try-catch
try {
    dangerous-operation
} catch {|err|
    print $"Error: ($err.msg)"
}

# Returning errors
def my-func [] {
    if $condition {
        error make {msg: "Something went wrong"}
    } else {
        "success"
    }
}

# Capture stdout, stderr, and exit status for an external command
let result = ^git --version | complete
if $result.exit_code != 0 {
    print $"Error: ($result.stderr)"
}
```

When the entire expression bound by `let` fits on one line, omit unnecessary
parentheses around its pipeline.

### Closures and Scoping

```nu
# Closures capture immutable variables
let multiplier = 10
let double_and_add = {|x| ($x * 2) + $multiplier}
do $double_and_add 5   # Returns 20

# Outer mutable variables CANNOT be captured in closures
mut sum = 0
[1 2 3] | each {|x| $sum = $sum + $x}  # ❌ WON'T COMPILE

# Use reduce instead
let sum = [1 2 3] | reduce {|x, acc| $acc + $x}
```

### Iteration Patterns

```nu
# each: transform each element
$list | each {|item| $item * 2}

# each --flatten: stream outputs instead of collecting
# Turns list<list<T>> into list<T> by streaming items as they arrive
glob *.txt --no-dir | each --flatten {|file| open --raw $file | lines } | find --no-highlight "TODO"

# each --keep-empty: preserve null results
[1 2 3] | each --keep-empty {|e| if $e == 2 { "found" }}
# Result: [null "found" null]  (vs. without flag: ["found"])

# where: select elements (`filter` was removed in 0.117)
# Row condition (field access auto-uses $it)
ls | where size > 100b           # Implicit: $it.size > 100b
ls | where type == "file"        # Implicit: $it.type == "file"

# Closure (must use $in or parameter)
$list | where {|x| $x > 10}
$list | where {$in > 10}         # Same as above

# reduce/fold: accumulate
$list | reduce --fold 0 {|item, acc| $acc + $item}

# Reduce without fold (first element is initial accumulator)
[1 2 3 4] | reduce {|it, acc| $acc - $it}  # ((1-2)-3)-4 = -8

# par-each: parallel processing
$large_list | par-each {|item| expensive-operation $item}

# for loop (imperative style)
for item in $list {
    print $item
}
```

### String Manipulation

```nu
# Interpolation
$"Hello ($name)!"
$"Sum: (1 + 2)"  # "Sum: 3"

# Split/join
"a,b,c" | split row ","        # ["a", "b", "c"]
["a", "b"] | str join ", "     # "a, b"

# Regex
"hello123" | parse --regex '(?<word>[a-z]+)(?<num>[0-9]+)'

# Multi-line strings
$"
Line 1
Line 2
"
```

### Glob Patterns (File Matching)

```nu
# Basic patterns
glob *.rs                         # All .rs files in current dir
glob **/*.rs                      # Recursive .rs files
glob **/*.{rs,toml}               # Multiple extensions
```

Use `glob` for path matches, `ls` when you need file metadata, and `find` to search values already in a pipeline. Nushell's `find` is not Unix `find` (`^find`).

### Module System

```nu
# Define module
module my_module {
    def private-greeting [] { "Hello" }
    export def greet [name: string] { $"(private-greeting), ($name)!" }

    export const MY_CONST = 42
    export type User = record<name: string, age: int>
}

# Use module
# Import selected exports, or use `use my_module *` to import all
use my_module [greet MY_CONST User]

# Import from file
# use lib/helpers.nu *
```

## Row Conditions vs Closures

`where` accepts either a **row condition** or a **closure**:

### Row Conditions (Short-hand Syntax)

```nu
# Automatic $it expansion on left side
ls | where size > 100b              # Expands to: $it.size > 100b
ls | where name =~ "test"           # Expands to: $it.name =~ "test"

ls | where modified older-than 2wk  # Duration-based comparison (0.117+)
```

**Limitations**:
- Cannot be stored in variables
- Only field access on left side auto-expands
- Subexpressions need explicit `$it`:
  ```nu
  ls | where ($it.name | str lowercase) =~ readme  # Need $it here
  ```

### Closures (Full Flexibility)

```nu
# Use $in or parameter name
ls | where {|row| $row.size > 100b}
ls | where {$in.size > 100b}

# Can be stored and reused
let big_files = {|row| $row.size > 1mb}
ls | where $big_files

# Use closures with commands that accept them
$list | each {|x| $x * 2}
$list | where {$in > 10}
```

**When to use**:
- Row conditions: Simple field comparisons (cleaner syntax)
- Closures: Complex logic, reusable conditions, nested operations

## Common Pitfalls

### `each` on Single Records

```nu
# ❌ Don't pass single records to each
let record = {a: 1, b: 2}
$record | each {|field| print $field}  # Only runs once!

# ✅ Use items, values, or transpose instead
$record | items {|key, val| print $"($key): ($val)"}
$record | transpose key val | each {|row| ...}
```

### Pipe vs Call Ambiguity

```nu
# These are different!
$list | my-func arg1 arg2   # $list piped, arg1 & arg2 as params
my-func $list arg1 arg2     # All three as positional params (if signature allows)
```

### Optional Fields

```nu
# ❌ Error if field doesn't exist
$record.missing  # ERROR

# ✅ Use ?
$record.missing?  # null
$record.missing? | default "N/A"  # "N/A"
```

### Empty Collections

```nu
# Empty list/table checks
if ($list | is-empty) { ... }

# Default value if empty
$list | default -e $val_if_empty
```

## Advanced Topics

For advanced patterns and deeper dives, see:

- **[references/advanced-patterns.md](references/advanced-patterns.md)** - Performance optimization, lazy evaluation, streaming, closures, memory-efficient patterns
- **[references/type-system.md](references/type-system.md)** - Type annotations, aliases, conversions, and type guards
- **[references/tui.md](references/tui.md)** - Build and test terminal pickers, forms, and live views with the built-in `tui` commands (0.116+)

## Best Practices

1. **Use type signatures** - helps catch errors early
2. **Prefer pipelines** - more idiomatic and composable
3. **Document with comments** - `#` for inline, also `#` above declarations for doc comments
4. **Export selectively** - don't pollute namespace
5. **Use `default`** - handle null/missing gracefully
6. **Validate inputs** - check types/ranges at function start
7. **Return consistent types** - don't mix null and values unexpectedly
8. **Use modules** - organize related functions
9. **Test incrementally** - build complex pipelines step-by-step
10. **Prefix external commands with caret** - `^grep` instead of just `grep`. Makes it clear it's not a nushell command, avoids ambiguity. **Nushell commands always have precedence**, e.g. `find` is NOT usual Unix `find` tool: use `^find`.
11. **Use dedicated external commands when needed** - for example, `^rg` for recursive text search or `^jq` for filtering JSON without first converting it to Nushell values.

## Debugging Techniques

```nu
# Print intermediate values
$data | each {|x| print $x; $x}  # Prints and passes through

# Inspect type
$value | describe

# Inspect a value without replacing the pipeline data
$data | inspect

# Timing
timeit { expensive-command }
```

## External Resources

- [Official Nushell Book](https://www.nushell.sh/book/)
- [Nushell Cookbook](https://www.nushell.sh/cookbook/)
- [Pipeline Input-Output Signatures](https://www.nushell.sh/book/custom_commands.html#pipeline-input-output-signature)
- [Module System](https://www.nushell.sh/book/modules.html)
- [Nushell 0.117.0 release notes](https://www.nushell.sh/blog/2026-11-09-nushell_v0_117_0.html)
