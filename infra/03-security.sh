#!/usr/bin/env bash
# 03 - Security Group sg-web (firewall da VM), com regras de menor privilégio.
#
# Entrada liberada: apenas HTTP (80) e HTTPS (443). Acesso ao banco ocorre apenas pela rede privada.
set -euo pipefail

cd "$(dirname "$0")"
source ./00-config.sh
ENV_INFRA="$(cd .. && pwd)/.env.infra"

command -v mgc >/dev/null || { echo "ERRO: mgc não encontrado."; exit 1; }

save_env() {
  local key="$1" val="$2"; touch "$ENV_INFRA"
  if grep -q "^${key}=" "$ENV_INFRA"; then
    sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$ENV_INFRA"
  else
    echo "${key}=\"${val}\"" >> "$ENV_INFRA"
  fi
}
_uuid() { grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1; }

regra() {
  mgc network security-groups rules create "$SG_WEB_ID" \
    --direction ingress --ethertype IPv4 --protocol tcp \
    --port-range-min "$2" --port-range-max "$2" \
    --remote-ip-prefix "$3" --description "$1" >/dev/null
  echo "  regra: $1 (tcp/$2 de $3)"
}

if [ -z "${SG_WEB_ID:-}" ]; then
  SG_WEB_ID=$(mgc network security-groups create --name "$SG_WEB_NAME" --region "$REGION" | _uuid)
  [ -n "$SG_WEB_ID" ] || { echo "ERRO: não obtive o id do Security Group."; exit 1; }
  save_env SG_WEB_ID "$SG_WEB_ID"
  echo "Security Group criado: $SG_WEB_ID"
  echo "Adicionando regras de entrada:"
  regra "HTTP publico"  80  "0.0.0.0/0"
  regra "HTTPS publico" 443 "0.0.0.0/0"
else
  echo "Security Group já registrado: $SG_WEB_ID (regras não recriadas)"
fi

echo "--- Verificação ---"
echo "mgc network security-groups get $SG_WEB_ID"
