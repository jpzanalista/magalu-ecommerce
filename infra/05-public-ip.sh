#!/usr/bin/env bash
# 05 - IP publico. Na Magalu ele costuma ser associado automaticamente a porta
#      da VM. Este script confirma o IP; o bloco de fallback reserva e associa
#      manualmente caso nao tenha vindo.
set -euo pipefail

cd "$(dirname "$0")"
source ./00-config.sh
ENV_INFRA="$(cd .. && pwd)/.env.infra"

command -v mgc >/dev/null || { echo "ERRO: mgc não encontrado."; exit 1; }
[ -n "${VM_ID:-}" ] || { echo "ERRO: VM_ID vazio (rode 04)."; exit 1; }

save_env() {
  local key="$1" val="$2"; touch "$ENV_INFRA"
  if grep -q "^${key}=" "$ENV_INFRA"; then
    sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$ENV_INFRA"
  else
    echo "${key}=\"${val}\"" >> "$ENV_INFRA"
  fi
}

PUBLIC_IP=$(mgc virtual-machine instances get "$VM_ID" -o json 2>/dev/null \
  | grep -oE '"associated_public_ipv4"[^,]*' \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1) || true

if [ -n "${PUBLIC_IP:-}" ]; then
  save_env PUBLIC_IP "$PUBLIC_IP"
  echo "IP publico ja associado a VM: $PUBLIC_IP"
else
  echo "Sem IP publico associado. Reservando e associando (fallback)..."
  PIP_ID=$(mgc network vpcs public-ips create --vpc-id "$VPC_ID" \
    --description "IP publico da $VM_NAME" \
    | grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1) || true
  [ -n "${PIP_ID:-}" ] || { echo "ERRO: não obtive o id do IP publico."; exit 1; }
  mgc network vpcs public-ips attach --vpc-id "$VPC_ID" --public-ip-id "$PIP_ID" --port-id "$VM_PORT_ID"
  echo "IP publico reservado e associado (id $PIP_ID)."
fi

echo "--- Verificação ---"
echo "mgc network vpcs public-ips list --vpc-id $VPC_ID"
