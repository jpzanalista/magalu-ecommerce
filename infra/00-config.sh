#!/usr/bin/env bash

# Região única: VM, DBaaS e bucket na mesma região
export REGION="br-se1"

# Rede
export VPC_NAME="vpc-movetech"
export POOL_NAME="pool-movetech"
export POOL_CIDR="10.0.0.0/16"
export SUBNET_PUBLICA_NAME="subnet-publica"
export SUBNET_PUBLICA_CIDR="10.0.1.0/24"
export SUBNET_PRIVADA_NAME="subnet-privada"
export SUBNET_PRIVADA_CIDR="10.0.2.0/24"

# Firewall (Security Group da VM).
export SG_WEB_NAME="sg-web"
export MEU_IP="${MEU_IP:-}"

# Compute
export VM_NAME="vm-ecommerce"
export VM_MACHINE_TYPE="BV1-1-10"
export VM_IMAGE="cloud-ubuntu-22.04 LTS"
export SSH_KEY_NAME="chave-ecommerce"

# Banco (DBaaS PostgreSQL 16)
export DB_NAME="db-movetech"
export DB_USER="movetech_admin"
export DB_ENGINE_ID="89bd25d5-e29e-4615-a64b-0a006bbc4997"

# Object Storage
export BUCKET_NAME="movetech-imagens"

# Carrega IDs/segredos gerados
_CFG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$_CFG_DIR/../.env.infra" ]; then
  set -a; . "$_CFG_DIR/../.env.infra"; set +a
fi
