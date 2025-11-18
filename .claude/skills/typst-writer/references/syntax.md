# Typst Syntax Reference

## Critical Syntax Distinctions

### Data Structures

- **Arrays**: Use `()` parentheses
  ```typst
  #let colors = (red, blue, green)
  #let mixed = (1, "text", true)
  ```

- **Dictionaries**: Use `()` with key-value pairs
  ```typst
  #let config = (name: "value", count: 5)
  #let palette = (primary: red, secondary: blue)
  ```

- **Content blocks**: Use `[]` square brackets
  ```typst
  #let heading = [== My Title]
  #let paragraph = [This is some *bold* text]
  ```

**IMPORTANT**: Typst does NOT have tuples. Only arrays (with parentheses).

### Function Definitions

```typst
// Basic function
#let greet(name) = [Hello, #name!]

// With default parameters
#let box-style(fill: none, stroke: 1pt) = { ... }

// With variadic arguments
#let items(..args) = {
  for item in args.pos() { ... }
}
```

### Conditionals and Loops

```typst
// If-else
#if condition {
  [true branch]
} else {
  [false branch]
}

// For loop
#for item in array {
  [Processing #item]
}
```

### String Interpolation

```typst
#let name = "World"
[Hello #name]  // Content context
#("Hello " + name)  // String concatenation
```

## Common Patterns

### Custom Styling Functions

```typst
#let highlight(color, body) = {
  box(fill: color.lighten(80%), inset: 3pt, body)
}

#highlight(red)[Important text]
```

### State Management

```typst
#let counter = state("my-counter", 0)

#counter.update(x => x + 1)

#context counter.get()
```

### Layout Helpers

```typst
// Stack (vertical by default)
#stack(
  spacing: 1em,
  [First item],
  [Second item]
)

// Grid
#grid(
  columns: (1fr, 2fr),
  rows: auto,
  gutter: 10pt,
  [Cell 1], [Cell 2]
)

// Box with styling
#box(
  fill: gray.lighten(90%),
  stroke: 1pt,
  inset: 8pt,
  radius: 4pt,
  [Content]
)
```

### Color Manipulation

```typst
#let base = rgb("#3366ff")
#let lighter = base.lighten(40%)
#let darker = base.darken(20%)
#let transparent = base.transparentize(50%)
#let mixed = red.mix(blue, 30%)
```

## Common Gotchas

1. **Array access**: Use `.at()` method, not `[]`
   ```typst
   #let arr = (1, 2, 3)
   #arr.at(0)  // Correct
   // arr[0]   // WRONG - [] is for content
   ```

2. **Method chaining on arrays**:
   ```typst
   #items.map(x => x * 2).filter(x => x > 5).join(", ")
   ```

3. **Context blocks**: Required for accessing state
   ```typst
   #context {
     let val = my-state.get()
     [The value is #val]
   }
   ```

4. **Assignment in code blocks**: Use `let`, not `=` alone
   ```typst
   #{
     let x = 5  // Correct
     // x = 5   // WRONG
   }
   ```
