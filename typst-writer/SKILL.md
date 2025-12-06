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

Besides compiling, the `typst` CLI command can also run queries against a Typst file with `typst query`, using Typst selectors,
and get the result as JSON.

For instance, `typst query the_document.typ "heading.where(level: 1)" | jq ".[].body.text"` will list all the level-1 section titles present in
the document. Sadly, it will not tell you their exact positions in the file, but Typst file are easy to grep.

See [https://typst.app/docs/reference/introspection/query/#command-line-queries](the online docs about `query`) for more info.

## Package Usage

When needing specialized functionality:
1. Search for packages at https://typst.app/universe/
2. Import with `#import "@preview/package:version"`
3. Consult package documentation for API

**Popular packages**:
- `cetz` (diagrams)
- `lilaq` (data visualization and plots)
- `drafting` (annotations/comments for work-in-progress docs)
- `gentle-clues` (callouts, tips, notes, admonitions)
- `showybox` (general-purpose, customizable text boxes, with headers and footers. E.g. for definitions, theorems or highlighting important paragraphs)
- `itemize` (nice layouts for item lists, enums, checklists, tree lists, etc.)
- `polylux` (presentations, slides)
- `suiji` (random number generation in Typst code)
- `zebraw` (code listings with line numbers, highlighted lines, inlined Typst comments/explanations etc.)
- `lovelace` (algorithms/pseudo-code)
- `jlyfish` (Typst as a Julia notebook: embed Julia code inside Typst to generate content, visualizations etc.)
- `pyrunner` (embed and call _non-I/O_ Python code inside Typst)
- `chronos` (sequence diagrams)
- `timeliney` (Gantt charts)
- `herodot` (linear timelines)
- `eqalc` (math equations to actual, callable Typst functions)
- `conchord` (lyrics with overlayed chord changes, guitar shapes and tabs)

## Working with Templates

Typst Universe hosts many pre-built templates for reports, papers, CVs, presentations, and more. Templates provide complete document styling and structure.

### Finding Templates

- Browse templates: https://typst.app/universe/search/?kind=templates
- Filter by category: report, paper, thesis, cv, etc.
- Check the template's documentation for parameters and examples

### Using a Template

1. Import the template: `#import "@preview/template-name:version": *`
2. Apply it with `#show: template-name.with(param: value, ...)`
3. Consult template documentation for required and optional parameters

**Example:**
```typst
#import "@preview/bubble:0.2.2": *

#show: bubble.with(
  title: "My Report",
  subtitle: "A detailed analysis",
  author: "Your Name",
  affiliation: "Your Organization",
  date: datetime.today(),
  main-color: rgb("#FF6B35"),
  color-words: ("important", "key", "critical"),
)

// Your content follows
= Introduction
...
```

**Key differences from packages:**
- Templates typically use `#show:` to apply styling to the entire document
- Packages provide functions/components you call explicitly
- Templates often have a title page and document structure built-in

**Popular templates**: `charged-ieee` (IEEE papers), `bubble` (colorful reports), `modern-cv` (CVs)

## Bibliographies and Citations

Typst supports citations and bibliographies using BibTeX (.bib) or Hayagriva (.yml) format files.

See [references/bibliography.md](references/bibliography.md)

## Complete Document Structure Patterns

### Academic Paper / Report

```typst
#set document(
  title: "Document Title",
  author: "Your Name",
  date: auto,
)

#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  numbering: "1",
)

#set text(size: 11pt)
#set par(justify: true)
#set heading(numbering: "1.")

// Title page
#align(center)[
  #text(size: 24pt, weight: "bold")[Document Title]

  #v(1cm)
  #text(size: 14pt)[Your Name]

  #v(0.5cm)
  #datetime.today().display()
]

#pagebreak()

// Table of contents
#outline(title: "Table of Contents", indent: auto)

#pagebreak()

// Main content
= Introduction
Your introduction text...

= Methods
...

= Results
...

= Conclusion
...

#pagebreak()

// Bibliography
#bibliography("refs.bib", title: "References", style: "ieee")
```

### Using Templates (Simpler)

```typst
#import "@preview/charged-ieee:0.1.4": *

#show: ieee.with(
  title: "Your Paper Title",
  authors: (
    (name: "Author One", email: "author1@example.com"),
    (name: "Author Two", email: "author2@example.com"),
  ),
  abstract: [
    Your abstract text here...
  ],
  index-terms: ("keyword1", "keyword2", "keyword3"),
  bibliography: bibliography("refs.bib"),
)

// Content starts immediately
= Introduction
Your paper content...
```

## Troubleshooting

### Missing Font Warnings

If you see "unknown font family" warnings, remove the font specification to use system defaults

**Note**: Font warnings don't prevent compilation; the document will use fallback fonts

### Template/Package Not Found

If import fails with "package not found":
- Verify exact package name and version on Typst Universe
- Check for typos in `@preview/package:version` syntax
- Ensure network connectivity (packages download on first use)
- **Remember**: Typst uses fully qualified imports with specific versions - there's no package cache to update

### Compilation Errors

Common fixes:
- **"expected content, found ..."**: You're using code where markup is expected - wrap in `#{ }` or use proper syntax
- **"expected expression, found ..."**: Missing `#` prefix in markup context
- **"unknown variable"**: Check spelling, ensure imports are correct
- **Array/dictionary errors**: Review syntax - use `()` for both, dictionaries need `key: value`

### Performance Issues

For large documents:
- Use `#include "file.typ"` to split into multiple files
- Compile specific pages: `typst compile doc.typ output.pdf --pages 1-5`
- Profile compilation (experimental): `typst compile --timings doc.typ`
