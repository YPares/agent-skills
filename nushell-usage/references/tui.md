# Building TUIs with Nushell

Nushell 0.116 introduced built-in `tui` commands. They compose a terminal UI
from ordinary Nushell values without a plugin. Use `input list` for a single
prompt, `explore` to browse arbitrary structured data, and `tui` when you need
your own layout, widgets, or actions. Run `help tui` to check what's available
in your installed version.

## Build, Run, Read the Result

Widget commands build up a `tui` value without drawing it. `tui run` opens it
on the terminal's alternate screen; `tui debug` renders and replays keys without
a terminal.

```nu
let picked = (
    ls
    | tui label --titlebar "Pick a file"
    | tui table --id files --columns [name type size]
    | tui run
)

if $picked.action == "submit" {
    $picked.selected.name
}
```

Arrow keys move the highlight, `Tab` and `Shift+Tab` move focus, and `Enter`
submits. Use `Esc` or `q` when not editing text, or `Ctrl+C` to quit.
`tui run --dialog --size [60 14]` opens a floating dialog instead of filling
the screen. `--no-mouse` leaves mouse selection to the terminal.

| Result field | Meaning |
| --- | --- |
| `action` | `submit` or `quit`; `tui debug` also returns `render` when no key ended the session |
| `selected` | Submitted value: a row, text, a button label, or a selection defined by a hook |
| `values` | Widget state keyed by widget ID, e.g. `$result.values.name` for a textbox with `--id name` |
| `focused`, `page` | Focused widget ID and zero-based page index |
| `rows`, `live` | Shared row count and whether a stream is still producing rows |

Check `action` before consuming `selected`. With `--multi` on a table or
select, `Space` checks rows and `Enter` submits the checked rows, or the
highlighted row if none are checked. `--index` submits positions instead of
the original values.

## Layout, Search, and Detail Panes

Outer widgets stack vertically. Use `tui split` for side-by-side panes
(`--vertical` to stack them), `tui box` for a bordered group, and `tui tab` for
top-level pages. Write each child as a parenthesized expression in the
container's child list.

```nu
def task-picker [] {
    [
        {name: "compile", detail: "Build the executable"}
        {name: "test", detail: "Run the test suite"}
        {name: "format", detail: "Format the source files"}
    ]
    | tui label --titlebar "Tasks"
    | tui split --sizes [40% 1fr] [
        (tui box "Tasks" [
            (tui search --bind / --columns [name])
            (tui table --id tasks --focus --columns [name])
        ])
        (tui preview --from tasks {|row| $row.detail })
    ]
}
```

Run `task-picker | tui run`. The outer pipeline supplies shared rows, but the
search box filters only lists in its box. `--columns [name]` on the table
changes what is displayed, not which fields are available to the preview.
Give linked widgets stable IDs: `--from tasks` makes this preview follow the
`tasks` table even when focus moves. With a row parameter the preview closure
receives that row; without a closure `tui preview` tries to read the path
in the row's `name` field (or the row itself if it is a string).

To give panes independent rows, pass `--data` or pipe into a child, e.g.
`tui split [(ls | tui table) (ps | tui table)]`. Don't combine `--data` and
`--from` on the same widget.

## Forms and Hooks

Use a textbox ID to read its value from a button hook. Return data to the
caller, then perform the requested operation **after** the TUI closes.

```nu
def name-form [] {
    tui label "Project name"
    | tui textbox --id name --focus --placeholder "e.g. demo"
    | tui button Save {|state|
        {action: submit, selected: $state.values.name}
    }
    | tui button Cancel { {action: quit} }
}
```

Run `name-form | tui run --dialog`. Press `Tab` from the textbox to focus Save,
then `Enter` to activate it. `Enter` in the textbox itself submits its text.

Hooks (`tui button`, `tui bind`, `--on-select`, menu actions, and the
`tui run` closure) take the UI state as a parameter or through `$in`:

| Return | Effect |
| --- | --- |
| `null` | Keep the current data and leave the UI open |
| A list or table | Replace shared rows; the previous stream stops adding rows |
| `{action: submit, selected: $value}` | Close and return `$value` as `selected` |
| `{action: quit}` | Close without submitting |

For a polled view, use `tui run --refresh 1sec { ls }`: the hook runs at
startup and then once per interval. For a key-triggered refresh, use
`tui bind ctrl+r { ls }` in the builder pipeline. Don't `print` from a hook
to report progress; it can interfere with rendering.

## Live Streams

Pipe rows straight into a builder so the UI can consume them as they arrive.
Avoid collecting a live stream with `let` **before** the builder.

```nu
1.. | each {|n| sleep 1sec; $"tick ($n)" } | tui log | tui run
```

`tui log` follows the newest lines; scrolling up pauses following and `End`
resumes it. For a file, substitute `^tail -f app.log` for the producer.
Use a finite stream for headless tests: `tui debug` waits for streams to end
(up to five seconds) before painting.

## Test Without a Terminal

Replay keys and check behavior instead of comparing an entire rendered screen.
These examples use `task-picker` and `name-form` defined above:

```nu
use std/assert

let picked = (task-picker | tui debug --keys "/,type:test,enter")
assert equal $picked.action "submit"
assert equal $picked.selected.name "test"

let saved = (name-form | tui debug --keys "type:demo,tab,enter")
assert equal $saved.action "submit"
assert equal $saved.selected "demo"

let cancelled = (name-form | tui debug --keys [tab right enter])
assert equal $cancelled.action "quit"
assert equal $cancelled.selected null
```

For layout troubleshooting, inspect `screen`, `widgets` (including their
resolved `rect`), `focus.order`, and `pages`. Use a fixed `--size [width height]`
to make a layout check repeatable.

See the [Nushell Book's TUI guide](https://www.nushell.sh/book/tui.html) for
widget options, keyboard and mouse behavior, and theming.
