use nu_plugin::{EvaluatedCall, MsgPackSerializer, serve_plugin};
use nu_plugin::{EngineInterface, Plugin, PluginCommand, SimplePluginCommand};
use nu_protocol::{LabeledError, Signature, SyntaxShape, Type, Value};

struct PLUGIN_NAMEPlugin;

impl Plugin for PLUGIN_NAMEPlugin {
    fn version(&self) -> String {
        env!("CARGO_PKG_VERSION").into()
    }

    fn commands(&self) -> Vec<Box<dyn PluginCommand<Plugin = Self>>> {
        vec![Box::new(PLUGIN_NAMECommand)]
    }
}

struct PLUGIN_NAMECommand;

impl SimplePluginCommand for PLUGIN_NAMECommand {
    type Plugin = PLUGIN_NAMEPlugin;

    fn name(&self) -> &str {
        "PLUGIN_NAME"
    }

    fn description(&self) -> &str {
        "A simple nushell plugin example"
    }

    fn signature(&self) -> Signature {
        Signature::build("PLUGIN_NAME")
            .input_output_type(Type::String, Type::Int)
            .named(
                "uppercase",
                SyntaxShape::Nothing,
                "convert to uppercase before counting",
                Some('u'),
            )
    }

    fn run(
        &self,
        _plugin: &PLUGIN_NAMEPlugin,
        _engine: &EngineInterface,
        call: &EvaluatedCall,
        input: &Value,
    ) -> Result<Value, LabeledError> {
        let uppercase = call.has_flag("uppercase")?;

        match input {
            Value::String { val, .. } => {
                let text = if uppercase {
                    val.to_uppercase()
                } else {
                    val.clone()
                };
                Ok(Value::int(text.len() as i64, call.head))
            }
            _ => Err(LabeledError::new("Expected string input")
                .with_label("requires string", call.head)),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use nu_plugin_test_support::PluginTest;
    use nu_protocol::{ShellError, Span};

    #[test]
    fn test_examples() -> Result<(), ShellError> {
        PluginTest::new("PLUGIN_NAME", PLUGIN_NAMEPlugin.into())?
            .test_examples(&PLUGIN_NAMECommand)
    }

    #[test]
    fn test_basic() -> Result<(), ShellError> {
        let plugin_test = PluginTest::new("PLUGIN_NAME", PLUGIN_NAMEPlugin.into())?;

        let result = plugin_test.eval_with(
            "PLUGIN_NAME",
            Value::string("hello", Span::test_data()),
        )?;

        assert_eq!(result, Value::int(5, Span::test_data()));
        Ok(())
    }
}

fn main() {
    serve_plugin(&PLUGIN_NAMEPlugin, MsgPackSerializer)
}
