---
name: typst-writer
description: Write correct and idiomatic Typst code for document typesetting. Use when creating or editing Typst (.typ) files, working with Typst markup, or answering questions about Typst syntax and features. Focuses on avoiding common syntax confusion (arrays vs content blocks, proper function definitions, state management).
---

# Typst Writer

This skill provides guidance for writing correct Typst code, with emphasis on avoiding common syntax errors from conflating Typst with other languages.

## Core Principles

1. **Never assume syntax from other languages applies** - Typst has its own semantics, especially for data structures
2. **Verify uncertain syntax** - When unsure, check official documentation
3. **Use idiomatic patterns** - Follow Typst conventions for clean, maintainable code

## Quick Syntax Reference

**Critical distinctions:**
- **Arrays**: `(item1, item2)` - parentheses
- **Dictionaries**: `(key: value, key2: value2)` - parentheses with colons
- **Content blocks**: `[markup content]` - square brackets
- **NO tuples** - Typst only has arrays

**For detailed syntax rules and common patterns**, see [references/syntax.md](references/syntax.md).

## Documentation Resources

### Official Documentation

- **Core language reference**: https://typst.app/docs/reference/
- **Package search**: https://typst.app/universe/search?kind=packages&q=QUERY
- **Template search**: https://typst.app/universe/search?kind=templates&q=QUERY

### When to Consult Documentation

- Uncertain about function signatures or parameters
- Need to verify syntax for less common features
- Looking for built-in functions or methods
- Exploring available packages (e.g., `cetz` for diagrams, `drafting` for margin notes, `tablex` for advanced tables)

**Use WebFetch when needed** to retrieve current documentation for verification.

## Workflow

1. **Before writing**: If syntax is unclear, consult [references/syntax.md](references/syntax.md) or documentation
2. **While writing**:
   - Use proper data structure syntax (arrays with `()`, content with `[]`)
   - Define functions with `#let name(params) = { ... }`
   - Use `context` blocks when accessing state
3. **After writing**: Review for Python/other language syntax leaking in

## Common Mistakes to Avoid

- ❌ Calling things "tuples" (Typst only has arrays)
- ❌ Using `[]` for arrays (use `()` instead)
- ❌ Accessing array elements with `arr[0]` (use `arr.at(0)`)
- ❌ Forgetting `#` prefix for code in markup context
- ❌ Mixing up content blocks `[]` with code blocks `{}`

## Example Workflow

```typst
// Define custom functions for document elements
#let important(body) = {
  box(
    fill: red.lighten(80%),
    stroke: red + 1pt,
    inset: 8pt,
    body
  )
}

// Use state for counters
#let example-counter = state("examples", 1)

#let example(body) = context {
  let num = example-counter.get()
  important[Example #num: #body]
  example-counter.update(x => x + 1)
}

// Arrays for data
#let factions = (
  (name: "Merchants", color: blue),
  (name: "Artisans", color: green)
)

// Iterate and render
#for faction in factions [
  - #text(fill: faction.color, faction.name)
]
```

## Reading contents from a Typst file

Besides compiling, the `typst` CLI command can also run queries against a Typst file with `typst query`, using typst selectors. See [https://typst.app/docs/reference/introspection/query/#command-line-queries](the docs).

## Package Usage

When needing specialized functionality:
1. Search for packages at https://typst.app/universe/
2. Import with `#import "@preview/package:version"`
3. Consult package documentation for API

**Popular packages**: `cetz` (diagrams), `drafting` (annotations), `tablex` (tables), `codelst` (code listings)
