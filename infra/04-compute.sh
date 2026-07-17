#!/usr/bin/env bash
# 04 - Compute: registra a chave SSH, cria a porta (VNIC) na sub-rede publica
#      com o sg-web, e cria a VM Ubuntu na sub-rede publica.
set -euo pipefail

cd "$(dirname "$0")"
source ./00-config.sh
ENV_INFRA="$(cd .. && pwd)/.env.infra"

command -v mgc >/dev/null || { echo "ERRO: mgc não encontrado."; exit 1; }
[ -n "${VPC_ID:-}" ]            || { echo "ERRO: VPC_ID vazio (rode 01)."; exit 1; }
[ -n "${SUBNET_PUBLICA_ID:-}" ] || { echo "ERRO: SUBNET_PUBLICA_ID vazio (rode 02)."; exit 1; }
[ -n "${SG_WEB_ID:-}" ]         || { echo "ERRO: SG_WEB_ID vazio (rode 03)."; exit 1; }

save_env() {
  local key="$1" val="$2"; touch "$ENV_INFRA"
  if grep -q "^${key}=" "$ENV_INFRA"; then
    sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$ENV_INFRA"
  else
    echo "${key}=\"${val}\"" >> "$ENV_INFRA"
  fi
}
_uuid() { grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1; }

# Chave SSH: registra a chave publica local se ainda nao estiver registrada
PUB="$HOME/.ssh/${SSH_KEY_NAME}.pub"
if mgc profile ssh-keys list -o json 2>/dev/null | grep -q "\"${SSH_KEY_NAME}\""; then
  echo "Chave SSH ja registrada: $SSH_KEY_NAME"
elif [ -f "$PUB" ]; then
  mgc profile ssh-keys create --name "$SSH_KEY_NAME" --key "$(cat "$PUB")" >/dev/null
  echo "Chave SSH registrada: $SSH_KEY_NAME"
else
  echo "ERRO: gere a chave: ssh-keygen -t ed25519 -f $HOME/.ssh/${SSH_KEY_NAME}"; exit 1
fi

# Porta (VNIC) na sub-rede publica, com o sg-web
if [ -n "${VM_PORT_ID:-}" ]; then
  echo "Porta ja registrada: $VM_PORT_ID"
else
  VM_PORT_ID=$(mgc network vpcs ports create "$VPC_ID" \
    --name "port-${VM_NAME}" \
    --subnets "[\"$SUBNET_PUBLICA_ID\"]" \
    --security-groups-id "[\"$SG_WEB_ID\"]" | _uuid) || true
  [ -n "$VM_PORT_ID" ] || { echo "ERRO: não obtive o id da porta."; exit 1; }
  save_env VM_PORT_ID "$VM_PORT_ID"; echo "Porta criada: $VM_PORT_ID"
fi

# VM: usa a porta -> cai na sub-rede publica; o IP publico e associado automaticamente
if [ -n "${VM_ID:-}" ]; then
  echo "VM ja registrada: $VM_ID"
else
  VM_ID=$(mgc virtual-machine instances create \
    --name "$VM_NAME" --image.name "$VM_IMAGE" \
    --machine-type.name "$VM_MACHINE_TYPE" --ssh-key-name "$SSH_KEY_NAME" \
    --availability-zone "br-se1-a" --network.interface.id="$VM_PORT_ID" | _uuid) || true
  [ -n "$VM_ID" ] || { echo "ERRO: não obtive o id da VM."; exit 1; }
  save_env VM_ID "$VM_ID"; echo "VM criada: $VM_ID"
fi

echo "--- Verificação ---"
echo "mgc virtual-machine instances get $VM_ID"
