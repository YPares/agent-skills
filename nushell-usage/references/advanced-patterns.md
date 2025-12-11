# Advanced Nushell Patterns

## Table of Contents

- [Performance Optimization](#performance-optimization) - Lazy vs eager evaluation, parallel processing, stream flattening
- [Advanced Closures](#advanced-closures) - Composition, currying, recursion
- [Advanced Record/Table Manipulation](#advanced-recordtable-manipulation) - Dynamic fields, joins, grouping
- [Working with Streams](#working-with-streams) - Custom streams, transformations
- [Advanced Error Handling](#advanced-error-handling) - Graceful degradation, error context
- [Memory-Efficient Patterns](#memory-efficient-patterns) - Large file processing, batching
- [Advanced Glob Patterns](#advanced-glob-patterns) - Complex patterns, depth limits
- [Custom Data Types](#custom-data-types) - Metadata, structured output

## Performance Optimization

### Lazy vs Eager Evaluation

```nu
# Lazy (streaming) - memory efficient for large data
large_file.csv | open | where status == "active" | first 10

# Eager (loads all) - faster for small datasets with multiple operations
let data = (large_file.csv | open | where status == "active")
$data | first 10
$data | last 10
$data | length
```

**When to use lazy:**
- Large files or streams
- Single-pass operations
- Memory constrained

**When to use eager:**
- Small datasets (< 10k rows)
- Multiple operations on same data
- Random access needed (though Nushell not great with random access, because no dedicated array/vector type, only lists)

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
ls *.txt | each {|f| open $f.name | lines }
# Returns: list<list<string>>

# With --flatten: streams items as they arrive
ls *.txt | each --flatten {|f| open $f.name | lines }
# Returns: list<string> (flattened)

# Practical example: search across files without waiting
ls **/*.nu | each --flatten {|f|
    open $f.name | lines | find "export def"
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

# Or with pipeline
let transform = {|x| $x | do $double | do $add_ten}
[1 2 3] | each $transform
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

### Recursive Closures

```nu
# Factorial using closure
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

### Table Joins

```nu
# Inner join
$users | join $orders user_id

# Outer join
$users | join --outer $orders user_id

# Left join
$users | join --left $orders user_id
```

### Group By Aggregations

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
# Generate infinite sequence
def fibonacci [] {
    mut a = 0
    mut b = 1
    loop {
        $a
        let temp = $b
        $b = $a + $b
        $a = $temp
    }
}

# Use with first to limit
fibonacci | first 10
```

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

## Advanced Error Handling

### Graceful Degradation

```nu
# Try multiple approaches, use first that works
def robust-fetch [url: string] {
    try {
        http get $url
    } catch {
        try {
            curl -s $url | from json
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
# ❌ Loads entire file into memory
open large.log | lines | where {$in =~ "ERROR"}

# ✅ Streams line-by-line
open large.log | lines | each --flatten {|line|
    if ($line =~ "ERROR") {$line}
}
```

### Batched Processing

```nu
# Process in chunks of 1000
open large.csv | chunks 1000 | each {|batch|
    $batch | process-batch
} | flatten
```

## Advanced Glob Patterns

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

# Preserve metadata through transformations
$value | str upcase  # Metadata preserved
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
