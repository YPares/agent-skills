# Advanced Nushell Patterns

## Table of Contents

- [Performance Optimization](#performance-optimization) - Lazy vs eager evaluation, parallel processing, stream flattening
- [Advanced Closures](#advanced-closures) - Composition, currying, recursion
- [Advanced Record/Table Manipulation](#advanced-recordtable-manipulation) - Dynamic fields, joins, grouping
- [Working with Streams](#working-with-streams) - Custom streams, transformations
- [Structured External Output](#structured-external-output) - Decode external output with `@structured`
- [Advanced Error Handling](#advanced-error-handling) - Graceful degradation, error context
- [Memory-Efficient Patterns](#memory-efficient-patterns) - Large file processing, batching
- [Advanced Glob Patterns](#advanced-glob-patterns) - Complex patterns, depth limits
- [Custom Data Types](#custom-data-types) - Metadata, structured output

## Performance Optimization

### Lazy vs Eager Evaluation

```nu
# Stream rows and stop after the first 10 matches
open --raw large_file.csv | from csv | where status == "active" | first 10

# Eager (loads all) - faster for small datasets with multiple operations
let data = (open --raw large_file.csv | from csv | where status == "active")
$data | first 10
$data | last 10
$data | length
```

**When to use lazy:**
- Large files or streams
- Single-pass operations
- Memory constrained

**When to use eager:**
- Data that fits comfortably in memory
- Multiple operations on same data
- Random access needed

To check whether rows are still streaming, pass the pipeline directly to
`describe --no-collect`: it reports `stream` without reading the rows.
Assigning to a variable first collects the stream.

### Parallel Processing

```nu
# Sequential - processes one at a time
$urls | each {|url| http get $url}

# Parallel - processes concurrently (faster for I/O)
$urls | par-each {|url| http get $url}

# Parallel with thread pool size
$urls | par-each --threads 4 {|url| http get $url}
```

**Best for:**
- I/O operations (HTTP requests, file reads)
- CPU-intensive transformations
- Independent operations (no shared state)

**Avoid for:**
- Small lists (overhead > benefit)
- Operations with side effects
- Order-dependent processing

### Avoiding Repeated Computation

```nu
# ❌ Recomputes expensive-func 3 times
if (expensive-func) > 10 {
    print (expensive-func)
    save-to-file (expensive-func)
}

# ✅ Compute once
let result = (expensive-func)
if $result > 10 {
    print $result
    save-to-file $result
}
```

### Stream Flattening

```nu
# Without --flatten: waits for each stream to complete
glob *.txt --no-dir | each {|file| open --raw $file | lines }
# Returns: list<list<string>>

# With --flatten: streams items as they arrive
glob *.txt --no-dir | each --flatten {|file| open --raw $file | lines }
# Returns: list<string> (flattened)

# Practical example: search across files without waiting
glob **/*.nu --no-dir | each --flatten {|file|
    open --raw $file | lines | find --no-highlight "export def"
} | str join "\n"
```

## Advanced Closures

### Closure Composition

```nu
# Build complex transformations from simple closures
let double = {|x| $x * 2}
let add_ten = {|x| $x + 10}

# Compose manually
[1 2 3] | each {|x| do $add_ten (do $double $x)}
# Result: [12, 14, 16]

# Or compose closures that take pipeline input rather than arguments
let double_input = {$in * 2}
let add_ten_input = {$in + 10}
[1 2 3] | each {$in | do $double_input | do $add_ten_input}
```

### Closure Currying Pattern

```nu
# Create specialized functions from general ones
def make-multiplier [factor: int] {
    {|x| $x * $factor}
}

let triple = (make-multiplier 3)
let quadruple = (make-multiplier 4)

[1 2 3] | each $triple     # [3, 6, 9]
[1 2 3] | each $quadruple  # [4, 8, 12]
```

### Recursive Custom Commands

```nu
# Factorial using a recursive command
def factorial [n: int] {
    if $n <= 1 {
        1
    } else {
        $n * (factorial ($n - 1))
    }
}

factorial 5  # 120
```

## Advanced Record/Table Manipulation

### Dynamic Field Access

```nu
# Access field by variable name
let field_name = "age"
$record | get $field_name

# Dynamic field update
let field_name = "status"
$record | update $field_name "active"

# Conditional field selection
let fields = if $detailed {["id", "name", "email"]} else {["id", "name"]}
$table | select ...$fields
```

Use `get ...$fields` (0.117+) to retrieve a list of values in path order
instead of preserving the record or table shape. Use `get --optional` for
missing paths; the old `--ignore-errors` flag was removed in 0.117.

### Table Joins

```nu
# Inner join
$users | join $orders user_id

# Outer join
$users | join --outer $orders user_id

# Left join
$users | join --left $orders user_id

# Anti join (0.117+): users with no matching order
$users | join --anti $orders user_id
```

### Group By Aggregations

In 0.117, `group-by --to-table` preserves the original key type and groups by
typed identity. Plain `group-by` still uses display strings as record keys, so
`true` and `"true"` can share a group without `--to-table`.

```nu
# Group and count
$sales | group-by category --to-table |
    insert count {|g| $g.items | length}

# Group and sum
$sales | group-by product --to-table |
    insert total {|g| $g.items | get price | math sum}

# Multiple aggregations
$sales | group-by category --to-table |
    insert stats {|g| {
        count: ($g.items | length)
        total: ($g.items | get price | math sum)
        avg: ($g.items | get price | math avg)
    }}
```

## Working with Streams

### Creating Custom Streams

```nu
# Emit one value per step; next carries state into the next invocation
def fibonacci [] {
    generate {|state|
        {out: $state.a, next: {a: $state.b, b: ($state.a + $state.b)}}
    } {a: 0, b: 1}
}

# Bound the stream before collecting it
fibonacci | first 10
# [0 1 1 2 3 5 8 13 21 34]
```

Omit `next` to end a `generate` stream. `loop` and `while` are control
flow, not stream producers, and cannot be piped in 0.117.

### Stream Transformations

```nu
# Skip while condition is true
$stream | skip while {|x| $x < 100}

# Take while condition is true
$stream | take while {|x| $x < 1000}

# Window (sliding window of N elements)
[1 2 3 4 5] | window 3
# [[1,2,3], [2,3,4], [3,4,5]]
```

## Structured External Output

In 0.117+, `@structured` on an `extern` declaration adds machine-readable
arguments and decodes the result when Nushell consumes the output (for example,
in `let` or when piping into an internal command):

```nu
@structured [--porcelain] { lines | parse --regex '^(?<status>..) (?<file>.+)$' }
extern "git status" []

git status | where status =~ M | get file  # Structured output
git status                                 # Normal Git display
```

Output sent directly to the terminal, to another external command, or redirected
to a file stays in the external command's normal format. See the
[release notes](https://www.nushell.sh/blog/2026-11-09-nushell_v0_117_0.html#structured-data-from-external-commands).

## Advanced Error Handling

### Graceful Degradation

```nu
# Try multiple approaches, use first that works
def robust-fetch [url: string] {
    try {
        http get $url
    } catch {
        try {
            ^curl --fail --silent --show-error $url | from json
        } catch {
            {error: "All fetch methods failed"}
        }
    }
}
```

### Error Context

```nu
# Add context to errors
def safe-divide [a: float, b: float] {
    if $b == 0 {
        error make {
            msg: "Division by zero"
            label: {
                text: $"Cannot divide ($a) by zero"
                span: (metadata $b).span
            }
        }
    } else {
        $a / $b
    }
}
```

## Memory-Efficient Patterns

### Processing Large Files Line-by-Line

```nu
# Stream bytes from the file, split into lines, and stop after 20 matches
open --raw large.log | lines | where {$in =~ "ERROR"} | first 20
```

### Batched Processing

```nu
# Process in chunks of 1000
open --raw large.csv | from csv | chunks 1000 | each --flatten {|batch|
    $batch | process-batch
}
```

Here `process-batch` is a custom command returning rows for each batch.

## Advanced Glob Patterns

These examples use the default 0.117 `glob` engine (Wax). With the experimental
[`dc-glob`](https://www.nushell.sh/blog/2026-11-09-nushell_v0_117_0.html#dc-glob-follows-nu-glob-s-rules-in-every-command-with-a-b-added)
option enabled, `glob` uses the same engine as `ls`, and Wax-specific repeat
patterns such as `<a*:3>` no longer work.

### Combining Multiple Patterns

```nu
# Match multiple file types
glob **/*.{rs,toml,md}

# Exclude multiple patterns
glob src/**/*.rs --exclude [**/target/** **/tests/**]

# Character classes
glob "[Cc]*"                      # Files starting with C or c
glob "[!cCbMs]*"                  # Files NOT starting with c, C, b, M, or s
glob "[A-Z]*" --no-file --no-symlink  # Only directories starting with uppercase
glob "src/[a-m]*.rs"  # Files starting with a-m
glob "tests/test_[!0-9]*.rs"  # Tests not starting with digit

# Advanced patterns (wax syntax)
glob "<a*:3>"                     # 3 a's in a row (e.g., "baaab.txt")
glob "<[a-d]:1,10>"               # 1-10 chars from [a-d]
glob "(?i)readme*"                # Case-insensitive

# Exclusions
glob **/tsconfig.json --exclude [**/node_modules/**]
glob **/* --exclude [**/target/** **/.git/** */]

# Follow symlinks
glob "**/*.txt" --follow-symlinks

# Depth limit
glob **/*.rs --depth 2            # Max 2 directories deep
```

### Depth-Limited Recursion

```nu
# Only 2 levels deep
glob **/*.rs --depth 2

# Find all package.json but not in deep node_modules
glob **/package.json --exclude [**/node_modules/**] --depth 5
```

## Custom Data Types

### Using Metadata

```nu
# Access span information for error reporting
let value = "hello"
metadata $value | get span

# Inspect pipeline metadata such as the source path
open --raw data.txt | metadata
```

### Building Structured Output

```nu
# Create consistent report format
def make-report [title: string, data: table]: nothing -> record<title: string, generated: datetime, row-count: int, columns: list<string>, data: table> {
    {
        title: $title
        generated: (date now)
        row-count: ($data | length)
        columns: ($data | columns)
        data: $data
    }
}
```
