#!/usr/bin/env bash
# Fixa servidor, chave e nome da aplicação Moto Fast Suporte no código-fonte.
# libs/hbb_common é um submódulo, por isso é alterado aqui em tempo de build.
set -euo pipefail

SERVER="suporte-api.motofast.pt"
API_SERVER="https://suporte-api.motofast.pt"
KEY="s6qp3tU+YIFgex22l0JQHNJcOi8Ajs4pqouULqC70ak="
# APP_NAME so aceita letras, numeros, hifen e sublinhado (validate_install_app_name)
APP_NAME="MotoFastSuporte"
DISPLAY_NAME="Moto Fast Suporte"

# Senha permanente predefinida: o valor em si nunca entra no repositório.
# Vem do secret MOTOFAST_PRESET_PASSWORD do GitHub Actions (ver motofast-windows.yml);
# aqui so calculamos o hash ("00" + base64(SHA-256(senha + salt))) a partir dele.
PRESET_SALT="motofast-suporte-2026"
if [ -z "${PRESET_PASSWORD:-}" ]; then
  echo "PRESET_PASSWORD nao definido (defina o secret MOTOFAST_PRESET_PASSWORD no repositorio)." >&2
  exit 1
fi
PRESET_STORAGE=$(PRESET_PASSWORD="$PRESET_PASSWORD" PRESET_SALT="$PRESET_SALT" python3 -c '
import base64, hashlib, os
pw = os.environ["PRESET_PASSWORD"]
salt = os.environ["PRESET_SALT"]
h1 = hashlib.sha256(pw.encode() + salt.encode()).digest()
print("00" + base64.b64encode(h1).decode())
')
unset PRESET_PASSWORD

CFG=libs/hbb_common/src/config.rs

sed -i -E "s|(RENDEZVOUS_SERVERS: &\[&str\] = &\[)[^]]*(\];)|\1\"${SERVER}\"\2|" "$CFG"
sed -i -E "s|(pub const RS_PUB_KEY: &str = )\"[^\"]*\";|\1\"${KEY}\";|" "$CFG"
sed -i -E "s|(APP_NAME: RwLock<String> = RwLock::new\()\"RustDesk\"|\1\"${APP_NAME}\"|" "$CFG"

# Opcoes por defeito no cliente: API (catalogo/dispositivos), servidor e chave
sed -i -E "s|(pub static ref DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = )Default::default\(\);|\1RwLock::new(HashMap::from([(\"api-server\".to_owned(), \"${API_SERVER}\".to_owned()), (\"custom-rendezvous-server\".to_owned(), \"${SERVER}\".to_owned()), (\"key\".to_owned(), \"${KEY}\".to_owned())]));|" "$CFG"

# Senha permanente predefinida via HARD_SETTINGS (mecanismo "preset password" do RustDesk)
sed -i -E "s|(pub static ref HARD_SETTINGS: RwLock<HashMap<String, String>> = )Default::default\(\);|\1RwLock::new(HashMap::from([(\"password\".to_owned(), \"${PRESET_STORAGE}\".to_owned()), (\"salt\".to_owned(), \"${PRESET_SALT}\".to_owned())]));|" "$CFG"

# Falha o build se alguma substituição não tiver sido aplicada.
grep -q "RENDEZVOUS_SERVERS: &\[&str\] = &\[\"${SERVER}\"\]" "$CFG"
grep -q "RS_PUB_KEY: &str = \"${KEY}\"" "$CFG"
grep -q "RwLock::new(\"${APP_NAME}\"" "$CFG"
grep -q "\"api-server\".to_owned(), \"${API_SERVER}\".to_owned()" "$CFG"
grep -q "\"custom-rendezvous-server\".to_owned(), \"${SERVER}\".to_owned()" "$CFG"
grep -q "(\"key\".to_owned(), \"${KEY}\".to_owned())" "$CFG"
grep -q "(\"password\".to_owned(), \"${PRESET_STORAGE}\".to_owned())" "$CFG"
grep -q "(\"salt\".to_owned(), \"${PRESET_SALT}\".to_owned())" "$CFG"

# Metadados do executável Windows
RC=flutter/windows/runner/Runner.rc
sed -i "s|\"RustDesk Remote Desktop\"|\"${DISPLAY_NAME}\"|; s|VALUE \"ProductName\", \"RustDesk\"|VALUE \"ProductName\", \"${DISPLAY_NAME}\"|" "$RC"
grep -q "ProductName\", \"${DISPLAY_NAME}\"" "$RC"

echo "Branding aplicado: ${APP_NAME} (${DISPLAY_NAME}) -> ${SERVER}"
