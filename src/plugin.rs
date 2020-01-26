use crate::keystore::{Keystore, PairExt, Status};
use flutter_engine::ffi::TextureId;
use flutter_engine::texture_registry::{RgbaTexture, Texture};
use flutter_plugins::prelude::*;
use image::RgbaImage;
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
    textures: Vec<Texture>,
}

impl Handler {
    fn create_texture(&mut self, engine: &FlutterEngine, img: RgbaImage) -> TextureId {
        let texture = engine.create_texture(RgbaTexture::new(img));
        let id = texture.id();
        self.textures.push(texture);
        id
    }
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
                Status::Uninitialized => Ok(Value::I64(0)),
                Status::Locked => Ok(Value::I64(1)),
                Status::Unlocked => Ok(Value::I64(2)),
            },
            "generate" => {
                let args = from_value::<PasswordArgs>(&call.args)?;
                self.keystore.generate(&args.password)?;
                Ok(Value::Null)
            }
            "import" => {
                let args = from_value::<ImportArgs>(&call.args)?;
                self.keystore.import(&args.phrase, &args.password)?;
                Ok(Value::Null)
            }
            "unlock" => {
                let args = from_value::<PasswordArgs>(&call.args)?;
                self.keystore.unlock(&args.password)?;
                Ok(Value::Null)
            }
            "lock" => {
                self.keystore.lock();
                Ok(Value::Null)
            }
            "paper_backup" => {
                let paper_backup = self.keystore.paper_backup()?;
                Ok(Value::Boolean(paper_backup))
            }
            "set_paper_backup" => {
                self.keystore.set_paper_backup()?;
                Ok(Value::Null)
            }
            "phrase" => {
                let args = from_value::<PasswordArgs>(&call.args)?;
                let phrase = self.keystore.phrase(&args.password)?;
                Ok(Value::String(phrase))
            }
            "account" => {
                let key = self.keystore.get_key(Some(0))?;
                let ss58 = key.ss58();
                let identicon = key.identicon()?;
                let qrcode = key.qrcode()?;

                let identicon = self.create_texture(&engine, identicon);
                let qrcode = self.create_texture(&engine, qrcode);
                let account = Account {
                    name: "/".to_string(),
                    ss58,
                    identicon,
                    qrcode,
                };
                Ok(to_value(account).expect("from known good value; qed"))
            }
            _ => Err(MethodCallError::NotImplemented),
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct Account {
    pub name: String,
    pub ss58: String,
    pub identicon: i64,
    pub qrcode: i64,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct PasswordArgs {
    pub password: String,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct ImportArgs {
    pub phrase: String,
    pub password: String,
}
