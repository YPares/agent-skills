# Styling with CSS

## CSS Files

Link external CSS file:

```python
class MyApp(App):
    CSS_PATH = "app.tcss"  # Textual CSS file
```

Or inline CSS:

```python
class MyApp(App):
    CSS = """
    Screen {
        background: $background;
    }
    """
```

## Selectors

### Type Selectors

Target all widgets of a type:

```css
Button {
    width: 100%;
}

Label {
    color: cyan;
}
```

### ID Selectors

Target specific widget:

```css
#my-button {
    background: red;
}

#header {
    dock: top;
}
```

### Class Selectors

Target widgets with specific class:

```css
.card {
    border: round white;
    padding: 1;
}

.selected {
    background: yellow;
}
```

Add classes in Python:

```python
widget = Label("Text", classes="card selected")
# or
widget.add_class("highlighted")
widget.remove_class("selected")
widget.toggle_class("active")
```

### Pseudo-classes

Style based on state:

```css
Button:hover {
    background: $accent;
}

Button:focus {
    border: double green;
}

Input:disabled {
    opacity: 0.5;
}
```

Common pseudo-classes: `:hover`, `:focus`, `:focus-within`, `:disabled`, `:enabled`

### Combinators

```css
/* Direct children */
Container > Label {
    color: white;
}

/* Descendants */
Container Label {
    margin: 1;
}

/* Class and type */
Label.card {
    border: round;
}
```

## Colors

### Named Colors

```css
Widget {
    color: red;
    background: blue;
    border: green;
}
```

### Hex Colors

```css
Widget {
    color: #ff0000;
    background: #00ff0088;  /* With alpha */
}
```

### RGB/RGBA

```css
Widget {
    color: rgb(255, 0, 0);
    background: rgba(0, 255, 0, 0.5);
}
```

### Theme Variables

Use built-in theme colors:

```css
Widget {
    background: $background;
    color: $text;
    border: $primary;
}
```

Common theme variables:
- `$background` - Main background
- `$surface` - Surface color
- `$panel` - Panel background
- `$boost` - Highlighted background
- `$primary` - Primary accent
- `$secondary` - Secondary accent
- `$accent` - Accent color
- `$text` - Main text color
- `$text-muted` - Muted text
- `$foreground-muted` - Dimmed foreground

## Borders

### Border Styles

```css
Widget {
    border: solid red;      /* Style and color */
    border: round cyan;     /* Rounded border */
    border: double white;   /* Double line */
    border: dashed yellow;  /* Dashed */
    border: heavy green;    /* Heavy/thick */
    border: tall blue;      /* Tall characters */
}
```

### Border Sides

```css
Widget {
    border-top: solid red;
    border-bottom: round blue;
    border-left: double green;
    border-right: dashed yellow;
}
```

### Border Title

```css
Widget {
    border: round white;
    border-title-align: center;
}
```

Set title in Python:

```python
widget.border_title = "My Widget"
```

## Text Styling

### Text Properties

```css
Label {
    text-style: bold;
    text-style: italic;
    text-style: bold italic;
    text-style: underline;
    text-style: strike;
}
```

### Text Alignment

```css
Static {
    text-align: left;
    text-align: center;
    text-align: right;
}
```

## Keylines

Add separators between grid cells or flex items:

```css
Grid {
    keyline: thin green;
    keyline: thick $primary;
}
```

Note: Must be on a container with a layout.

## Opacity

```css
Widget {
    opacity: 0.5;    /* 50% transparent */
    opacity: 0;      /* Fully transparent */
    opacity: 1;      /* Fully opaque */
}
```

## Tint

Apply color overlay:

```css
Widget {
    tint: rgba(255, 0, 0, 0.3);  /* Red tint */
}
```

## Rich Markup

Use Rich markup in text:

```python
label = Label("[bold cyan]Hello[/bold cyan] [red]World[/red]")
label.update("[underline]Updated[/underline]")
```

Common markup:
- `[bold]...[/bold]` - Bold
- `[italic]...[/italic]` - Italic
- `[color]...[/color]` - Colored (e.g., `[red]`, `[#ff0000]`)
- `[underline]...[/underline]` - Underline
- `[strike]...[/strike]` - Strikethrough
- `[link=...]...[/link]` - Link

## Example: Card Styling

```css
.card {
    width: 12;
    height: 10;
    border: round $secondary;
    background: $panel;
    padding: 1;
    content-align: center middle;
}

.card:hover {
    background: $boost;
    border: heavy $primary;
}

.card.selected {
    background: $accent;
    border: double $primary;
}

.card.disabled {
    opacity: 0.5;
    tint: rgba(0, 0, 0, 0.5);
}

.card-title {
    text-style: bold;
    text-align: center;
    color: $text;
}

.card-value {
    text-align: center;
    color: $text-muted;
}
```
