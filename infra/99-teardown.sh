#!/usr/bin/env bash
# 99 - Remove TODOS os recursos do e-commerce (ordem inversa de dependencia).
set -uo pipefail

cd "$(dirname "$0")"
source ./00-config.sh

echo "!!! Isto vai APAGAR toda a infraestrutura (VM, banco, rede, bucket). !!!"
read -r -p "Digite 'SIM' para confirmar: " RESP
[ "$RESP" = "SIM" ] || { echo "Cancelado."; exit 0; }

del() { echo "-> $*"; "$@" >/dev/null 2>&1 && echo "   ok" || echo "   (falhou ou ja removido)"; }

# 1) Banco (custo)
[ -n "${DBAAS_ID:-}" ]         && del mgc dbaas instances delete "$DBAAS_ID" --no-confirm
# 2) VM + IP publico (custo)
[ -n "${VM_ID:-}" ]            && del mgc virtual-machine instances delete --id "$VM_ID" --delete-public-ip --no-confirm
# 3) Porta (VNIC) da VM
[ -n "${VM_PORT_ID:-}" ]       && del mgc network ports delete --port-id "$VM_PORT_ID" --no-confirm
# 4) Security groups
[ -n "${SG_WEB_ID:-}" ]        && del mgc network security-groups delete --security-group-id "$SG_WEB_ID" --no-confirm
[ -n "${SG_DB_ID:-}" ]         && del mgc network security-groups delete --security-group-id "$SG_DB_ID" --no-confirm
# 5) Sub-redes
[ -n "${SUBNET_PUBLICA_ID:-}" ] && del mgc network subnets delete --subnet-id "$SUBNET_PUBLICA_ID" --no-confirm
[ -n "${SUBNET_PRIVADA_ID:-}" ] && del mgc network subnets delete --subnet-id "$SUBNET_PRIVADA_ID" --no-confirm
# 6) Subnet pool
[ -n "${SUBNETPOOL_ID:-}" ]    && del mgc network subnetpools delete --subnetpool-id "$SUBNETPOOL_ID" --no-confirm
# 7) VPC
[ -n "${VPC_ID:-}" ]           && del mgc network vpcs delete --id "$VPC_ID" --no-confirm
# 8) Bucket (conteudo + bucket)
mgc object-storage buckets delete --bucket "$BUCKET_NAME" --recursive --no-confirm || true

echo
echo "Concluido. Itens de conta (remova a mao se quiser):"
echo "  - Credencial S3 (movetech-imagekit): mgc object-storage api-key revoke"
echo "  - Chave SSH (chave-ecommerce):       mgc profile ssh-keys delete"
echo "  - Origem no ImageKit: remova pelo painel do ImageKit."
echo "Confira no console se nao restou nada ativo (custo)."
