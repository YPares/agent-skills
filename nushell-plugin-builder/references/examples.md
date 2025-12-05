# Common Plugin Patterns and Examples

## Simple Value Transformation

Transform input values to output values:

```rust
use nu_plugin::{EvaluatedCall, EngineInterface, SimplePluginCommand};
use nu_protocol::{LabeledError, Signature, Type, Value};

struct Uppercase;

impl SimplePluginCommand for Uppercase {
    type Plugin = MyPlugin;

    fn name(&self) -> &str { "uppercase" }

    fn signature(&self) -> Signature {
        Signature::build("uppercase")
            .input_output_type(Type::String, Type::String)
    }

    fn run(
        &self,
        _plugin: &MyPlugin,
        _engine: &EngineInterface,
        call: &EvaluatedCall,
        input: &Value,
    ) -> Result<Value, LabeledError> {
        match input {
            Value::String { val, .. } => {
                Ok(Value::string(val.to_uppercase(), call.head))
            }
            _ => Err(LabeledError::new("requires string input")
                .with_label("expected string", input.span()))
        }
    }
}
```

## Filter Command (Streaming)

Filter items from a list stream:

```rust
use nu_plugin::PluginCommand;
use nu_protocol::{PipelineData, ListStream};

struct FilterEven;

impl PluginCommand for FilterEven {
    type Plugin = MyPlugin;

    fn name(&self) -> &str { "filter-even" }

    fn signature(&self) -> Signature {
        Signature::build("filter-even")
            .input_output_type(
                Type::List(Box::new(Type::Int)),
                Type::List(Box::new(Type::Int))
            )
    }

    fn run(
        &self,
        _plugin: &MyPlugin,
        _engine: &EngineInterface,
        call: &EvaluatedCall,
        input: PipelineData,
    ) -> Result<PipelineData, LabeledError> {
        let filtered = input.into_iter().filter_map(|value| {
            if let Value::Int { val, .. } = value {
                if val % 2 == 0 {
                    return Some(value);
                }
            }
            None
        });

        Ok(PipelineData::ListStream(
            ListStream::new(filtered, call.head, None),
            None
        ))
    }
}
```

## Table Generation

Generate a table of records:

```rust
struct ListFiles;

impl SimplePluginCommand for ListFiles {
    type Plugin = MyPlugin;

    fn name(&self) -> &str { "list-files" }

    fn signature(&self) -> Signature {
        Signature::build("list-files")
            .required("path", SyntaxShape::Filepath, "directory to list")
    }

    fn run(
        &self,
        _plugin: &MyPlugin,
        engine: &EngineInterface,
        call: &EvaluatedCall,
        _input: &Value,
    ) -> Result<Value, LabeledError> {
        let path: String = call.req(0)?;
        let base_dir = engine.get_current_dir()?;
        let full_path = base_dir.join(path);

        let entries = std::fs::read_dir(full_path)
            .map_err(|e| LabeledError::new(format!("Failed to read directory: {}", e)))?;

        let mut records = vec![];
        for entry in entries {
            let entry = entry.map_err(|e| LabeledError::new(e.to_string()))?;
            let metadata = entry.metadata()
                .map_err(|e| LabeledError::new(e.to_string()))?;

            records.push(Value::record(
                record! {
                    "name" => Value::string(entry.file_name().to_string_lossy(), call.head),
                    "size" => Value::filesize(metadata.len() as i64, call.head),
                    "is_dir" => Value::bool(metadata.is_dir(), call.head),
                },
                call.head,
            ));
        }

        Ok(Value::list(records, call.head))
    }
}
```

## External API Call

Make HTTP requests and return data:

```rust
use serde::Deserialize;

#[derive(Deserialize)]
struct ApiResponse {
    message: String,
    status: u16,
}

struct ApiCall;

impl SimplePluginCommand for ApiCall {
    type Plugin = MyPlugin;

    fn name(&self) -> &str { "api-get" }

    fn signature(&self) -> Signature {
        Signature::build("api-get")
            .required("url", SyntaxShape::String, "API endpoint")
    }

    fn run(
        &self,
        _plugin: &MyPlugin,
        _engine: &EngineInterface,
        call: &EvaluatedCall,
        _input: &Value,
    ) -> Result<Value, LabeledError> {
        let url: String = call.req(0)?;

        // Note: In real plugin, use async runtime or blocking HTTP client
        let response: ApiResponse = reqwest::blocking::get(&url)
            .map_err(|e| LabeledError::new(format!("Request failed: {}", e)))?
            .json()
            .map_err(|e| LabeledError::new(format!("Parse failed: {}", e)))?;

        Ok(Value::record(
            record! {
                "message" => Value::string(response.message, call.head),
                "status" => Value::int(response.status as i64, call.head),
            },
            call.head,
        ))
    }
}
```

## Configuration-Based Command

Use plugin-specific configuration:

```rust
struct Configured;

impl SimplePluginCommand for Configured {
    type Plugin = MyPlugin;

    fn name(&self) -> &str { "configured" }

    fn signature(&self) -> Signature {
        Signature::build("configured")
    }

    fn run(
        &self,
        _plugin: &MyPlugin,
        engine: &EngineInterface,
        call: &EvaluatedCall,
        _input: &Value,
    ) -> Result<Value, LabeledError> {
        // Get plugin config from $env.config.plugins.my_plugin
        let config = engine.get_plugin_config()?;

        // Extract specific setting
        let setting = config
            .and_then(|c| c.get("my_setting"))
            .and_then(|v| v.as_str())
            .unwrap_or("default");

        Ok(Value::string(format!("Using setting: {}", setting), call.head))
    }
}
```

## Multi-Command Plugin

Plugin with multiple related commands:

```rust
struct MathPlugin;

impl Plugin for MathPlugin {
    fn version(&self) -> String {
        env!("CARGO_PKG_VERSION").into()
    }

    fn commands(&self) -> Vec<Box<dyn PluginCommand<Plugin = Self>>> {
        vec![
            Box::new(Add),
            Box::new(Multiply),
            Box::new(Power),
        ]
    }
}

struct Add;
impl SimplePluginCommand for Add {
    type Plugin = MathPlugin;
    fn name(&self) -> &str { "math add" }
    // ...
}

struct Multiply;
impl SimplePluginCommand for Multiply {
    type Plugin = MathPlugin;
    fn name(&self) -> &str { "math multiply" }
    // ...
}

struct Power;
impl SimplePluginCommand for Power {
    type Plugin = MathPlugin;
    fn name(&self) -> &str { "math power" }
    // ...
}
```

## Real-World Plugin Examples

For production-ready examples, see:

- **[nushell/plugin-examples](https://github.com/nushell/plugin-examples)** - Official examples repository
- **[nushell/awesome-nu](https://github.com/nushell/awesome-nu)** - Curated list of community plugins including:
  - `nu_plugin_compress` - Compression/decompression plugin
  - `nu_plugin_bin_reader` - Binary data reading
  - `nu_plugin_dbus` - D-Bus interaction
  - `nu_plugin_highlight` - Syntax highlighting
  - `nu_plugin_audio_hook` - Audio playback

Browse more at [GitHub: nushell-plugin topic](https://github.com/topics/nushell-plugin?l=rust).
