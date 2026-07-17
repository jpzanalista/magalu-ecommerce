#!/usr/bin/env bash
# 07 - Object Storage: bucket privado + imagem de teste.
#
set -euo pipefail

cd "$(dirname "$0")"
source ./00-config.sh
command -v mgc >/dev/null || { echo "ERRO: mgc não encontrado."; exit 1; }

# Bucket privado
mgc object-storage buckets create --bucket "$BUCKET_NAME" --private 2>/dev/null \
  && echo "Bucket $BUCKET_NAME criado (privado)." \
  || echo "Bucket $BUCKET_NAME ja existe (ok)."

# Imagem de teste em produtos/
[ -f /tmp/produto-teste.jpg ] || curl -sL "https://picsum.photos/600/400" -o /tmp/produto-teste.jpg
mgc object-storage objects upload --src /tmp/produto-teste.jpg \
  --dst "$BUCKET_NAME/produtos/produto-teste.jpg"

echo "--- Verificação ---"
echo "mgc object-storage buckets acl get --dst $BUCKET_NAME"
echo "Origem ImageKit: https://br-se1.magaluobjects.com/$BUCKET_NAME/"
