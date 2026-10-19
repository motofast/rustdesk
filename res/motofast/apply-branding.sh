#!/usr/bin/env bash
# Fixa servidor, chave e nome da aplicação Moto Fast Suporte no código-fonte.
# libs/hbb_common é um submódulo, por isso é alterado aqui em tempo de build.
set -euo pipefail

SERVER="suporte.motofast.pt"
KEY="s6qp3tU+YIFgex22l0JQHNJcOi8Ajs4pqouULqC70ak="
APP_NAME="Moto Fast Suporte"

CFG=libs/hbb_common/src/config.rs

sed -i -E "s|(RENDEZVOUS_SERVERS: &\[&str\] = &\[)[^]]*(\];)|\1\"${SERVER}\"\2|" "$CFG"
sed -i -E "s|(pub const RS_PUB_KEY: &str = )\"[^\"]*\";|\1\"${KEY}\";|" "$CFG"
sed -i -E "s|(APP_NAME: RwLock<String> = RwLock::new\()\"RustDesk\"|\1\"${APP_NAME}\"|" "$CFG"

# Falha o build se alguma substituição não tiver sido aplicada.
grep -q "RENDEZVOUS_SERVERS: &\[&str\] = &\[\"${SERVER}\"\]" "$CFG"
grep -q "RS_PUB_KEY: &str = \"${KEY}\"" "$CFG"
grep -q "RwLock::new(\"${APP_NAME}\"" "$CFG"

# Metadados do executável Windows
RC=flutter/windows/runner/Runner.rc
sed -i "s|\"RustDesk Remote Desktop\"|\"${APP_NAME}\"|; s|VALUE \"ProductName\", \"RustDesk\"|VALUE \"ProductName\", \"${APP_NAME}\"|" "$RC"
grep -q "ProductName\", \"${APP_NAME}\"" "$RC"

echo "Branding aplicado: ${APP_NAME} -> ${SERVER}"
