# nu_plugin_PLUGIN_NAME

A Nushell plugin that counts string length.

## Building

```bash
cargo build --release
```

## Installation

```bash
# Install to cargo bin
cargo install --path . --locked

# Register with nushell
plugin add ~/.cargo/bin/nu_plugin_PLUGIN_NAME  # Add .exe on Windows
plugin use PLUGIN_NAME
```

## Usage

```nushell
# Basic usage
"hello world" | PLUGIN_NAME
# => 11

# With uppercase flag
"hello world" | PLUGIN_NAME --uppercase
# => 11 (same length, but processes "HELLO WORLD")
```

## Testing

```bash
cargo test
```
