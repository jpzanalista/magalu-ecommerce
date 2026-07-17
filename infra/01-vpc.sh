#!/usr/bin/env bash
# 01 - Cria a VPC e o subnet pool do e-commerce MoveTech.
set -euo pipefail

cd "$(dirname "$0")"
source ./00-config.sh
ENV_INFRA="$(cd .. && pwd)/.env.infra"

# Pré-requisitos
command -v mgc >/dev/null || { echo "ERRO: mgc não encontrado no PATH."; exit 1; }
mgc auth access-token >/dev/null 2>&1 || { echo "ERRO: não autenticado. Rode: mgc auth login"; exit 1; }

# Grava (ou atualiza) uma variável no .env.infra
save_env() {
  local key="$1" val="$2"; touch "$ENV_INFRA"
  if grep -q "^${key}=" "$ENV_INFRA"; then
    sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$ENV_INFRA"
  else
    echo "${key}=\"${val}\"" >> "$ENV_INFRA"
  fi
}
_uuid() { grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1; }

# VPC (reusa se já registrada no .env.infra)
if [ -n "${VPC_ID:-}" ]; then
  echo "VPC já registrada: $VPC_ID"
else
  VPC_ID=$(mgc network vpcs create --name "$VPC_NAME" --region "$REGION" | _uuid)
  [ -n "$VPC_ID" ] || { echo "ERRO: não obtive o id da VPC."; exit 1; }
  save_env VPC_ID "$VPC_ID"; echo "VPC criada: $VPC_ID"
fi

# Subnet pool
if [ -n "${SUBNETPOOL_ID:-}" ]; then
  echo "Subnet pool já registrado: $SUBNETPOOL_ID"
else
  SUBNETPOOL_ID=$(mgc network subnetpools create \
    --name "$POOL_NAME" --description "Pool de sub-redes do e-commerce MoveTech" \
    --cidr "$POOL_CIDR" --type default --region "$REGION" | _uuid)
  [ -n "$SUBNETPOOL_ID" ] || { echo "ERRO: não obtive o id do subnet pool."; exit 1; }
  save_env SUBNETPOOL_ID "$SUBNETPOOL_ID"; echo "Subnet pool criado: $SUBNETPOOL_ID"
fi

echo "--- Verificação ---"
echo "mgc network vpcs get $VPC_ID"
