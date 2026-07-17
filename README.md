# magalu-ecommerce — Infraestrutura MoveTech (Magalu Cloud)

Provisionamento da infraestrutura de um e-commerce (empresa fictícia **MoveTech**) usando exclusivamente serviços da **Magalu Cloud**. A aplicação não é implantada — o foco é a infraestrutura, a segurança e as justificativas técnicas.

## Arquitetura

Usuário → IP público → Firewall (Security Group) → VM na sub-rede pública →
PostgreSQL (DBaaS, sem IP público). Imagens dos produtos no Object Storage,
distribuídas por CDN (ImageKit). Região: **br-se1**.

Diagrama em `docs/diagrama/`.

## Recursos

| Camada | Recurso | Nome |
|---|---|---|
| Rede | VPC + sub-redes | `vpc-movetech` · `subnet-publica` 10.0.1.0/24 · `subnet-privada` 10.0.2.0/24 |
| Segurança | Security Group | `sg-web` (80/443 público, 22 restrito) |
| Rede pública | IP público | associado à VM |
| Compute | VM Ubuntu 22.04 | `vm-ecommerce` |
| Banco | PostgreSQL DBaaS | `db-movetech` (sem acesso público) |
| Armazenamento | Object Storage | bucket `movetech-imagens` |
| CDN | ImageKit (origem S3) | distribuição das imagens |

## Conteúdo

- `docs/console-passo-a-passo.md` — provisionamento pelo Console, com checkpoints de evidência.
- `docs/justificativas.md` — respostas técnicas.
- `infra/` — os mesmos recursos como scripts `mgc` de referência.

Ordem: 01-vpc → 02-subnets → 03-security → 04-compute → 05-public-ip →
06-dbaas → 07-storage → 08-validate. Remoção: 99-teardown.

## Segredos

Credenciais ficam em `.env.infra`, fora do controle de versão ver `.env.infra.example`.

## Custos e limpeza

VM, IP público e DBaaS geram cobrança enquanto ativos. Ao terminar o desafio, removerei os recursos (99-teardown ou pelo console) para não consumir o saldo, e quem sabe o saldo do meu humilde cartão de crédito s2.