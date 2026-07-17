#!/usr/bin/env bash
# 06 - DBaaS PostgreSQL privado + sg-db (firewall do banco).
#
# O DBaaS nao tem IP publico (privado por padrao) -> atende "sem acesso publico".
# O sg-db (5432 apenas da sub-rede publica) e o controle de acesso pretendido;

set -euo pipefail

cd "$(dirname "$0")"
source ./00-config.sh
ENV_INFRA="$(cd .. && pwd)/.env.infra"

command -v mgc >/dev/null || { echo "ERRO: mgc não encontrado."; exit 1; }
[ -n "${DBAAS_PASSWORD:-}" ] || { echo "ERRO: defina DBAAS_PASSWORD no .env.infra."; exit 1; }

save_env() {
  local key="$1" val="$2"; touch "$ENV_INFRA"
  if grep -q "^${key}=" "$ENV_INFRA"; then
    sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$ENV_INFRA"
  else
    echo "${key}=\"${val}\"" >> "$ENV_INFRA"
  fi
}
_uuid() { grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1; }

# sg-db: firewall do banco (5432 apenas da sub-rede publica)
if [ -n "${SG_DB_ID:-}" ]; then
  echo "sg-db ja registrado: $SG_DB_ID"
else
  SG_DB_ID=$(mgc network security-groups create --name "sg-db" --region "$REGION" | _uuid) || true
  [ -n "$SG_DB_ID" ] || { echo "ERRO: nao obtive o id do sg-db."; exit 1; }
  save_env SG_DB_ID "$SG_DB_ID"
  mgc network security-groups rules create "$SG_DB_ID" \
    --direction ingress --ethertype IPv4 --protocol tcp \
    --port-range-min 5432 --port-range-max 5432 \
    --remote-ip-prefix "$SUBNET_PUBLICA_CIDR" \
    --description "PostgreSQL da sub-rede publica" >/dev/null
  echo "sg-db criado: $SG_DB_ID (regra 5432 adicionada)"
fi

# Banco PostgreSQL privado
if [ -n "${DBAAS_ID:-}" ]; then
  echo "DBaaS ja registrado: $DBAAS_ID"
else
  # Para anexar o firewall do banco, acrescente: --security-groups "[\"$SG_DB_ID\"]"
  DBAAS_ID=$(mgc dbaas instances create \
    --name "$DB_NAME" --engine-id "$DB_ENGINE_ID" \
    --instance-type-id "9f99f51e-4405-4c29-867f-46a642ce5f42" \
    --user "$DB_USER" --password "$DBAAS_PASSWORD" \
    --volume.size 20 --volume.type "CLOUD_NVME15K" \
    --availability-zone "br-se1-b" --region "$REGION" | _uuid) || true
  [ -n "$DBAAS_ID" ] || { echo "ERRO: nao obtive o id do DBaaS."; exit 1; }
  save_env DBAAS_ID "$DBAAS_ID"; echo "DBaaS criado: $DBAAS_ID (aguarde ACTIVE)"
fi

echo "--- Verificação ---"
echo "mgc dbaas instances get $DBAAS_ID"
