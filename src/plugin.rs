use crate::keystore::{Keystore, PairExt, Status};
use flutter_plugins::prelude::*;
use std::sync::Arc;

const PLUGIN_NAME: &str = module_path!();
const CHANNEL_NAME: &str = "rust/keystore";

#[derive(Default)]
pub struct KeystorePlugin {
    handler: Arc<RwLock<Handler>>,
}

#[derive(Default)]
struct Handler {
    keystore: Keystore,
}

impl Plugin for KeystorePlugin {
    fn plugin_name() -> &'static str {
        PLUGIN_NAME
    }

    fn init_channels(&mut self, registrar: &mut ChannelRegistrar) {
        let method_handler = Arc::downgrade(&self.handler);
        registrar.register_channel(StandardMethodChannel::new(CHANNEL_NAME, method_handler));
    }
}

impl MethodCallHandler for Handler {
    fn on_method_call(
        &mut self,
        call: MethodCall,
        engine: FlutterEngine,
    ) -> Result<Value, MethodCallError> {
        match call.method.as_str() {
            "status" => match self.keystore.status() {
                Status::Empty => Ok(Value::I64(0)),
                Status::KeyFile => Ok(Value::I64(1)),
            },
            "generate" => {
                let args = from_value::<PasswordArgs>(&call.args)?;
                self.keystore.generate(&args.password)?;
                return Ok(Value::Null);
            }
            "import" => {
                let args = from_value::<ImportArgs>(&call.args)?;
                self.keystore.import(&args.phrase, &args.password)?;
                return Ok(Value::Null);
            }
            "load" => {
                let args = from_value::<PasswordArgs>(&call.args)?;
                self.keystore.load(&args.password)?;
                return Ok(Value::Null);
            }
            "phrase" => {
                let args = from_value::<PasswordArgs>(&call.args)?;
                let phrase = self.keystore.phrase(&args.password)?;
                return Ok(Value::String(phrase));
            }
            "info" => {
                let key = self.keystore.get_key(Some(0))?;
                let blocky = engine.create_texture(key.blocky()?);
                let qr = engine.create_texture(key.qr()?);
                Ok(json_value!({
                    "ss58": key.ss58(),
                    "blocky": blocky,
                    "qr": qr,
                }))
            }
            _ => Err(MethodCallError::NotImplemented),
        }
    }
}

/*struct KeyInfo {
    pub ss58: String,
    pub blocky: i64,
    pub qr: i64,
}*/

#[derive(Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct PasswordArgs {
    pub password: String,
}

#[derive(Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct ImportArgs {
    pub phrase: String,
    pub password: String,
}
