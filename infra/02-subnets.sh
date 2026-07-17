#!/usr/bin/env bash
# 02 - Cria as sub-redes pública e privada na VPC.
set -euo pipefail

cd "$(dirname "$0")"
source ./00-config.sh
ENV_INFRA="$(cd .. && pwd)/.env.infra"

command -v mgc >/dev/null || { echo "ERRO: mgc não encontrado."; exit 1; }
[ -n "${VPC_ID:-}" ] || { echo "ERRO: VPC_ID vazio. Rode 01-vpc.sh antes."; exit 1; }

save_env() {
  local key="$1" val="$2"; touch "$ENV_INFRA"
  if grep -q "^${key}=" "$ENV_INFRA"; then
    sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$ENV_INFRA"
  else
    echo "${key}=\"${val}\"" >> "$ENV_INFRA"
  fi
}
_uuid() { grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1; }

criar_subnet() {
  local nome="$1" cidr="$2" var="$3"
  if [ -n "${!var:-}" ]; then echo "$nome já registrada: ${!var}"; return; fi
  local id
  id=$(mgc network vpcs subnets create "$VPC_ID" \
    --name "$nome" --cidr-block "$cidr" --ip-version 4 \
    --subnetpool-id "$SUBNETPOOL_ID" --region "$REGION" | _uuid)
  [ -n "$id" ] || { echo "ERRO: não obtive o id de $nome."; exit 1; }
  save_env "$var" "$id"; echo "$nome criada: $id"
}

criar_subnet "$SUBNET_PUBLICA_NAME" "$SUBNET_PUBLICA_CIDR" SUBNET_PUBLICA_ID
criar_subnet "$SUBNET_PRIVADA_NAME" "$SUBNET_PRIVADA_CIDR" SUBNET_PRIVADA_ID

echo "--- Verificação ---"
echo "No console: VPC vpc-movetech -> aba Subnet"
