# Advanced Plugin Features

## Streaming with PipelineData

For commands that work with streams (like processing lists or large datasets), use `PipelineData` instead of `Value`.

### Basic Streaming Example
```rust
use nu_plugin::PluginCommand;  // Note: Not SimplePluginCommand
use nu_protocol::PipelineData;

impl PluginCommand for MyStreamingCommand {
    type Plugin = MyPlugin;

    fn run(
        &self,
        plugin: &MyPlugin,
        engine: &EngineInterface,
        call: &EvaluatedCall,
        input: PipelineData,
    ) -> Result<PipelineData, LabeledError> {
        // Process stream lazily
        let result = input.into_iter().map(|value| {
            // Transform each value
            process_value(value, call.head)
        });

        Ok(PipelineData::ListStream(
            ListStream::new(result, call.head, None),
            None
        ))
    }
}
```

### PipelineData Variants

**Empty** - No data
```rust
PipelineData::Empty
```

**Value** - Single value
```rust
PipelineData::Value(Value::int(42, span), None)
```

**ListStream** - Stream of values (lazy)
```rust
PipelineData::ListStream(ListStream::new(iterator, span, None), None)
```

**ByteStream** - Raw byte stream
```rust
PipelineData::ByteStream(byte_stream, None)
```

### Counting Stream Items
```rust
fn run(&self, input: PipelineData, call: &EvaluatedCall) -> Result<PipelineData, LabeledError> {
    let count = input.into_iter().count();
    Ok(Value::int(count as i64, call.head).into_pipeline_data())
}
```

## Engine Interface

The `EngineInterface` provides methods to interact with the Nushell engine during execution.

### Environment Variables
```rust
// Set environment variable in caller's scope
engine.add_env_var("MY_VAR", Value::string("value", call.head))?;

// Get environment variable
let home = engine.get_env_var("HOME")?;
```

**Important:** Environment variables must be set **before** sending the plugin response to propagate to the caller's scope.

### Configuration Access
```rust
// Get full Nushell configuration
let config = engine.get_config()?;

// Get plugin-specific config from $env.config.plugins.PLUGIN_NAME
let plugin_config = engine.get_plugin_config()?;
```

### Current Directory
```rust
let current_dir = engine.get_current_dir()?;
let file_path = current_dir.join("data.json");
```

### Evaluation
```rust
// Evaluate Nushell expression in engine context
let result = engine.eval("ls | length")?;
```

## Custom Values

Custom values allow plugins to introduce their own data types beyond Nushell's built-in types.

### Defining a Custom Value

**Important:** The `#[typetag::serde]` macro is required on the `impl CustomValue` block for proper serialization across the plugin protocol.

```rust
use nu_protocol::{CustomValue, ShellError, Span, Value};
use serde::{Deserialize, Serialize};
use std::any::Any;

#[derive(Clone, Debug, Serialize, Deserialize)]
struct MyCustomValue {
    data: String,
}

#[typetag::serde]  // Required for plugin serialization!
impl CustomValue for MyCustomValue {
    fn clone_value(&self, span: Span) -> Value {
        Value::custom(Box::new(self.clone()), span)
    }

    fn type_name(&self) -> String {
        "MyCustomType".to_string()
    }

    fn to_base_value(&self, span: Span) -> Result<Value, ShellError> {
        // Define how to convert to a standard Value
        Ok(Value::string(&self.data, span))
    }

    fn as_any(&self) -> &dyn Any {
        self
    }

    fn as_mut_any(&mut self) -> &mut dyn Any {
        self
    }
}
```

### Returning Custom Values
```rust
fn run(&self, ...) -> Result<Value, LabeledError> {
    let custom = MyCustomValue {
        data: "example".to_string(),
    };
    Ok(Value::custom(Box::new(custom), call.head))
}
```

### Operating on Custom Values
```rust
fn run(&self, input: &Value, ...) -> Result<Value, LabeledError> {
    if let Ok(custom) = input.as_custom_value() {
        if let Some(my_value) = custom.as_any().downcast_ref::<MyCustomValue>() {
            // Work with your custom type
            return Ok(Value::string(&my_value.data, input.span()));
        }
    }
    Err(LabeledError::new("Expected MyCustomType"))
}
```

### Cargo Dependencies for Custom Values

Add the `typetag` crate to your `Cargo.toml`:
```toml
[dependencies]
nu-plugin = "0.109.1"
nu-protocol = "0.109.1"
serde = { version = "1", features = ["derive"] }
typetag = "0.2"
```

### Notes on Custom Values

- Custom values work with the `save` command
- Plugins can define custom serialization behavior
- Custom values behave like regular Values in most contexts
- **Avoid enum-based custom values** - they have known issues with bincode deserialization

## Signatures and Type Annotations

### Input-Output Types
```rust
use nu_protocol::{Signature, Type};

Signature::build("my-command")
    .input_output_type(Type::String, Type::Int)
    .input_output_type(Type::List(Box::new(Type::String)), Type::Int)
```

### Named Parameters
```rust
Signature::build("my-command")
    .named("output", SyntaxShape::Filepath, "output file", Some('o'))
    .named("format", SyntaxShape::String, "output format", Some('f'))
    .switch("verbose", "enable verbose output", Some('v'))
```

### Positional Parameters
```rust
Signature::build("my-command")
    .required("input", SyntaxShape::String, "input string")
    .optional("count", SyntaxShape::Int, "repeat count")
    .rest("files", SyntaxShape::Filepath, "files to process")
```

### Accessing Parameters
```rust
fn run(&self, call: &EvaluatedCall, ...) -> Result<Value, LabeledError> {
    let output_file: Option<String> = call.get_flag("output")?;
    let is_verbose: bool = call.has_flag("verbose")?;
    let input: String = call.req(0)?;  // First positional arg
    let count: Option<i64> = call.opt(1)?;  // Second positional arg
    let files: Vec<String> = call.rest(2)?;  // Remaining args
}
```

## Examples in Signatures

Add examples to help users understand your command:
```rust
use nu_protocol::Example;

fn signature(&self) -> Signature {
    Signature::build("my-command")
        .input_output_type(Type::String, Type::Int)
}

fn examples(&self) -> Vec<Example> {
    vec![
        Example {
            description: "Count characters in a string",
            example: "\"hello\" | my-command",
            result: Some(Value::int(5, Span::test_data())),
        },
    ]
}
```

## References
- [EngineInterface docs](https://docs.rs/nu-plugin/latest/nu_plugin/struct.EngineInterface.html)
- [Custom values PR #11911](https://github.com/nushell/nushell/pull/11911)
- [PipelineData docs](https://docs.rs/nu-protocol/latest/nu_protocol/enum.PipelineData.html)
