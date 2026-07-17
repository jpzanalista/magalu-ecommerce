# CDN — ImageKit (distribuição das imagens de produto)

A CDN distribui as imagens do produto (armazenadas no Object Storage **privado**) com
cache global e transformações em tempo real (resize, WebP, etc.). Usamos o
**ImageKit.io** com o bucket da Magalu como **origem S3-compatible**.

## Por que assim
- O bucket `movetech-imagens` é **privado** — a internet não o acessa diretamente.
- O ImageKit lê o bucket via **credencial S3** e serve as imagens pela CDN.
- O público acessa as imagens **somente pela URL da CDN**, nunca o bucket direto.

## Credenciais necessárias
Geradas no Object Storage (`mgc object-storage api-key create`) e guardadas no
`.env.infra` (fora do git):
- `OS_ACCESS_KEY`  = access key (key_pair_id)
- `OS_SECRET_KEY`  = secret key (key_pair_secret)

## Passo a passo (ImageKit)
1. Criar conta em https://imagekit.io (plano free) e fazer login.
2. Dashboard -> **External storage -> Add New**.
3. **Origin type:** *S3-Compatible Storage*. Nome: `magalu-movetech`.
4. Preencher:
   - **Bucket name:** `movetech-imagens`
   - **Bucket folder:** `/`  (raiz)
   - **Access key / Secret key:** os valores de `OS_ACCESS_KEY` / `OS_SECRET_KEY`
   - **Endpoint:** `https://br-se1.magaluobjects.com`
5. Salvar e anexar a origem ao **URL endpoint** padrão (`https://ik.imagekit.io/movetechmagalu`).

## URLs de acesso (troque movetechmagalu pelo seu ImageKit ID)
- Original via CDN:
  `https://ik.imagekit.io/movetechmagalu/produtos/produto-teste.jpg`
- Com transformação (largura 300px + WebP):
  `https://ik.imagekit.io/movetechmagalu/produtos/produto-teste.jpg?tr=w-300,f-webp`

## Fluxo
Usuário -> URL da CDN (ImageKit) -> [cache] -> na primeira vez, ImageKit busca no
bucket privado (via credencial S3) -> entrega otimizada e cacheada ao usuário.

Fonte: https://imagekit.io/docs/integration/s3-compatible-storage
