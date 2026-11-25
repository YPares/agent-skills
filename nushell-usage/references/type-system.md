# Nushell Type System

## Table of Contents

- [Common Types and Annotations](#common-types-and-annotations) - Common values and signature types
- [Type Annotations](#type-annotations) - Function signatures, complex types
- [Built-in Scalar Types](#built-in-scalar-types) - Numbers, strings, dates, durations, filesizes, binary, glob
- [Collection Types](#collection-types) - Lists, records, tables, ranges
- [Type Conversions](#type-conversions) - Explicit conversions, type checking
- [Closure Type](#closure-type) - Closure values and parameters
- [Type Narrowing and Guards](#type-narrowing-and-guards) - Optional types, type guards
- [Generic Containers](#generic-containers) - Concrete element types versus `any`
- [Type Coercion](#type-coercion) - Automatic coercion, avoiding issues
- [Advanced Type Patterns](#advanced-type-patterns) - Discriminated unions, option types

## Common Types and Annotations

| Kind | Examples |
| --- | --- |
| Scalar values | `nothing` (`null`), `bool`, `int`, `float`, `string`, `datetime`, `duration`, `filesize`, `binary`, `glob`, `range`, `cell-path` |
| Collections | `list<int>`, `record<name: string, age: int>`, `table<name: string, age: int>` |
| Callables | `closure` |
| Broad annotations | `any`, `number` (int or float), `oneof<int, string>` |

For the current type annotations and parser shapes, see the
[Nushell Book](https://www.nushell.sh/book/custom_commands.html#parameter-types).

## Type Annotations

### Function Signatures

```nu
# No types (accepts any)
def identity-arg [x] { $x }

# Typed parameters
def format-pair [x: int, y: string] { $"($x): ($y)" }

# Pipeline types
def text-length []: string -> int { str length }

# Both pipeline and parameters
def scale [multiplier: int]: list<int> -> list<int> {
    each {|x| $x * $multiplier}
}

# Optional parameters with defaults
def show-options [
    x: int
    y: int = 10           # Default value
    --flag                # Named flag (no type --> BOOLEAN)
    --option: string      # Named param (null if not passed)
    --foo: string = "bar" # Named param with default value
] { [$x $y $flag $option $foo] }
```

### Complex Types

```nu
# Lists
def count-names [items: list<string>] { $items | length }
def count-rows [matrix: list<list<int>>] { $matrix | length }

# Records
def get-host [config: record<host: string, port: int>] { $config.host }

# Tables (list of records)
def get-names [data: table<name: string, age: int>] { $data.name }

# Union types (oneof)
def display-value [value: oneof<int, string>] { $"($value)" }

# A closure parameter accepts a callable without declaring its return type
def run-transform [transform: closure] { do $transform }
```

### Reusable Type Aliases (0.117+)

```nu
module geometry {
    export type Point = record<x: float, y: float>
}

use geometry Point
type Polygon = list<Point>
def first-x [poly: Polygon]: nothing -> float { $poly.0.x }
first-x [{x: 1.0, y: 2.0}]  # 1.0
```

Define aliases before use. Import exported aliases explicitly (`use geometry
Point` or `use geometry *`); bare `use geometry` does not import them. An alias
does not create a distinct type or take type parameters. `type` is now reserved:
rename commands called `type`, or use `^type` for an external executable.

## Built-in Scalar Types

### Numbers

```nu
# Integers
42                    # int
0xFF                  # hexadecimal
0o77                  # octal
0b1010                # binary

# Floats
3.14                  # float
1.5e-3                # scientific notation
-inf                  # negative infinity
inf                   # infinity
NaN                   # not a number

# Number type (union of int and float)
def add [a: number, b: number]: nothing -> number {
    $a + $b
}
```

### Strings

```nu
# Basic strings
"hello"
'world'

# Interpolated strings
$"Hello ($name)!"
$"Result: (1 + 2)"   # "Result: 3"

# Multi-line strings
$"
Line 1
Line 2
"

# Raw strings do not escape or interpolate; the opening and closing hash counts must match
r###'C:\Users\name'###
```

### Dates and Durations

```nu
# Dates
date now              # Current datetime
"2024-01-15" | into datetime
"2024-01-15T10:30:00Z" | into datetime

# Durations
1sec, 5min, 2hr, 3day, 1wk
500ms + 2sec          # 2.5sec
1day - 6hr            # 18hr

# Duration math
(date now) + 5day     # 5 days from now
(date now) - 1wk      # 1 week ago
```

### Filesizes

```nu
# File sizes
1kb, 500mb, 2gb, 1tb
1024 | into filesize  # 1024 bytes (1 KiB)

# Filesize math
100mb + 50mb          # 150mb
1gb / 4               # 250mb
```

### Binary Data

```nu
# Binary literals
0x[01 FF 3A 00]

# Convert to/from binary
"hello" | into binary
0x[68656c6c6f] | decode utf-8  # "hello"

# Binary operations
let data = (open --raw file.bin | into binary)
```

### Glob Patterns

```nu
# Store a pattern without expanding it
let pattern = ("**/*.md" | into glob)
$pattern | describe  # glob

# Expand it to matched paths
glob $pattern
```

## Collection Types

### Lists

```nu
# Homogeneous lists (preferred)
let numbers: list<int> = [1, 2, 3]
let names: list<string> = ["Alice", "Bob"]

# Heterogeneous lists (list<any>)
let mixed = [1, "two", 3.0]

# Nested lists
let matrix: list<list<int>> = [
    [1, 2, 3]
    [4, 5, 6]
]

# Empty list
[]
let empty: list<int> = []
```

### Records

```nu
# Simple records
{name: "Alice", age: 30}

# Typed record fields
let config: record<host: string, port: int> = {
    host: "localhost"
    port: 8080
}

# Nested records
{
    user: {
        name: "Alice"
        contact: {
            email: "alice@example.com"
        }
    }
}

# Empty record
{}
```

### Tables

```nu
# Table is list<record>
let users: table = [
    {name: "Alice", age: 30}
    {name: "Bob", age: 25}
]

# All records should have same fields for proper table
let consistent_table = [
    {id: 1, name: "Alice", active: true}
    {id: 2, name: "Bob", active: false}
]
```

### Ranges

```nu
# Inclusive ranges
1..5                  # [1, 2, 3, 4, 5]
0..10                 # [0, 1, 2, ..., 10]

# Exclusive end
1..<5                 # [1, 2, 3, 4]

# The middle number is the second value, not the step
1..3..10              # [1, 3, 5, 7, 9]
0..5..20              # [0, 5, 10, 15, 20]

# Reverse ranges
5..1                  # [5, 4, 3, 2, 1]

# Use seq char for character sequences
seq char a e          # [a, b, c, d, e]
```

## Type Conversions

### Explicit Conversions

```nu
# To string
42 | into string                # "42"
[1, 2, 3] | into string         # ["1", "2", "3"]
[1, 2, 3] | to nuon             # "[1, 2, 3]"

# To int
"42" | into int                 # 42
3.7 | into int                  # 3 (truncate)

# To float
"3.14" | into float             # 3.14
42 | into float                 # 42.0

# To bool
"true" | into bool              # true
1 | into bool                   # true
0 | into bool                   # false

# To binary
"hello" | into binary
0x[68656c6c6f]

# To datetime
"2024-01-15" | into datetime
1705334400 | into datetime      # From unix timestamp

# To filesize
1024 | into filesize            # 1024 bytes (1 KiB)
"500MB" | into filesize         # 500mb

# To duration
60 | into duration --unit sec   # 1min
```

### Type Checking

```nu
# Check type
$value | describe               # Returns type as string

# Examples
42 | describe                   # "int"
[1, 2, 3] | describe            # "list<int>"
{a: 1} | describe               # "record<a: int>"

# Type predicates (custom)
def is-int [] {
    ($in | describe) == "int"
}

def is-list [] {
    ($in | describe) starts-with "list"
}
```

## Closure Type

```nu
# Simple closure
let double = {|x: int| $x * 2}

# Closure type annotation
def apply [
    value: int
    func: closure
]: nothing -> int {
    do $func $value
}

apply 5 $double  # 10

# Multi-parameter closure
let add = {|x, y| $x + $y}
do $add 3 4  # 7
```

## Type Narrowing and Guards

### Optional Types

```nu
# Fields may or may not exist
$record.field?                  # null if missing
$record.field? | default 0      # Provide default

# Optional function parameters
def func [
    required: int
    optional?: string           # May be null
] {
    if ($optional != null) {
        print $optional
    }
}
```

### Type Guards in Practice

```nu
# Check before use
def safe-process [value: any] {
    match ($value | describe) {
        "int" => ($value * 2)
        "string" => ($value | str uppercase)
        $kind if ($kind starts-with "list<") => ($value | length)
        _ => null
    }
}

# With if conditions
def process [x: any] {
    if (($x | describe) == "int") {
        $x + 10
    } else if (($x | describe) == "string") {
        $"Got: ($x)"
    } else {
        "Unknown type"
    }
}
```

## Generic Containers

`list<any>` accepts lists with different element types. The signature does not
promise a specific output element type or tie it to the input type.

```nu
# Map over any list; output element types depend on the closure
def my-map [transform: closure]: list<any> -> list<any> {
    $in | each $transform
}

[1, 2, 3] | my-map {|x| $x * 2}  # [2, 4, 6]
["a", "b"] | my-map {|x| $x | str uppercase}  # ["A", "B"]
```

## Type Coercion

Don't rely on automatic conversion between text and numbers. Interpolation
formats values as text, and numeric operators can accept mixed numeric types
(`1 + 2.5` produces `3.5`).

```nu
# NO
"5" + 3                 # TYPE ERROR

# YES
$"Value: (42)"          # "Value: 42"

# YES
"5" + (3 | into string) # "53"

# Boolean to int
true | into int         # 1
false | into int        # 0

# Be explicit when precision matters
let x = ("3.14" | into float)
let y = ("2.0" | into float)
$x + $y

# Type-safe comparisons
42 == "42"            # false (different types)
42 == ("42" | into int)  # true
```

## Advanced Type Patterns

### Discriminated Unions

```nu
# Using records with type field
let result = {
    type: "success"
    value: 42
}

let error = {
    type: "error"
    message: "Failed"
}

# Pattern match on type
match $result.type {
    "success" => $result.value
    "error" => {
        print $result.message
    }
}
```
