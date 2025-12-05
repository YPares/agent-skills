# Plugin Protocol and Serialization

## Communication Model

Nushell plugins are standalone executables that communicate with the Nushell engine over stdin/stdout using a standardized serialization protocol. The plugin never directly interacts with the user's terminal—all I/O goes through the engine.

## Serialization Formats

Two serialization formats are supported:

**MsgPackSerializer** (Recommended)
- Binary format, significantly faster
- Use for production plugins
- More compact message size

**JsonSerializer**
- Text-based, human-readable
- Useful for debugging and learning
- Slower but easier to inspect

Choose the serializer in `main()`:
```rust
use nu_plugin::{MsgPackSerializer, serve_plugin};

fn main() {
    serve_plugin(&MyPlugin, MsgPackSerializer)  // Production
    // serve_plugin(&MyPlugin, JsonSerializer)  // Debug
}
```

## Plugin Lifecycle

### 1. Discovery Phase
When running `plugin add <path>`, Nushell:
1. Executes the plugin binary
2. Requests plugin metadata (version, commands)
3. Stores signatures in the plugin registry file

### 2. Loading Phase
When running `plugin use <name>`:
1. Loads plugin signatures from registry
2. Makes commands available in current session
3. Plugin is **not** executed yet

### 3. Execution Phase
When a plugin command is invoked:
1. Nushell spawns the plugin process
2. Plugin receives serialized input and call context
3. Plugin processes data and returns serialized output
4. Process may stay alive for subsequent calls (persistent mode)

## Important Constraints

### Stdio Restrictions
**Plugins cannot use stdin/stdout for their own purposes** because these streams are reserved for protocol communication.

Check before using stdio:
```rust
use nu_plugin::EngineInterface;

fn run(&self, engine: &EngineInterface, ...) -> Result<Value, LabeledError> {
    if engine.is_using_stdio() {
        return Err(LabeledError::new("Cannot read stdin in plugin mode"));
    }
    // Safe to use stdin here
}
```

### Path Handling
Always use paths relative to the engine's current directory:
```rust
let current_dir = engine.get_current_dir()?;
let full_path = current_dir.join(relative_path);
```

## Stream IDs

When working with streams (ListStream, ByteStream), the protocol assigns stream IDs for tracking. The `serve_plugin()` function handles this automatically, but custom protocol implementations must manage stream ID allocation.

Stream messages reference an integer ID starting at zero, specified by the producer.

## Error Handling

Errors should be returned as `LabeledError` with proper span information:
```rust
Err(LabeledError::new("Error message")
    .with_label("specific issue", call.head))
```

This allows Nushell to show exactly where the error occurred in the user's command.

## References
- [Plugin Protocol Reference](https://www.nushell.sh/contributor-book/plugin_protocol_reference.html)
- [PipelineData docs](https://docs.rs/nu-protocol/latest/nu_protocol/enum.PipelineData.html)
