# magalu-ecommerce — Infraestrutura MoveTech (Magalu Cloud)

Provisionamento da infraestrutura de um e-commerce (empresa fictícia **MoveTech**)
usando exclusivamente serviços da **Magalu Cloud**, via **MGC CLI**. A aplicação não
foi implantada — o foco é a infraestrutura, a segurança e as justificativas técnicas.

## Arquitetura

Usuário → IP público → Firewall (Security Group) → VM na sub-rede pública →
PostgreSQL (DBaaS, privado, sem IP público). Imagens dos produtos no Object Storage
(bucket privado), distribuídas por CDN (ImageKit). Região: **br-se1**.

Diagrama em [`docs/diagrama/`](docs/diagrama/).

## Recursos provisionados

| Camada | Recurso | Detalhe |
|---|---|---|
| Rede | VPC + sub-redes | `vpc-movetech` · pública `10.0.1.0/24` · privada `10.0.2.0/24` |
| Segurança | Security Groups | `sg-web` (80/443 público) · `sg-db` (5432 da sub-rede pública) |
| Rede pública | IP público | associado à VM |
| Compute | VM Ubuntu 22.04 | `vm-ecommerce` (sub-rede pública) |
| Banco | PostgreSQL 16 (DBaaS) | `db-movetech` — privado, sem acesso público |
| Armazenamento | Object Storage | bucket privado `movetech-imagens` |
| CDN | ImageKit (origem S3) | distribui as imagens com transformações |

## Estrutura do repositório

- [`infra/`](infra/) — scripts `mgc` numerados (`00-config` → `07-storage`, `99-teardown`).
- [`docs/justificativas.md`](docs/justificativas.md) — respostas técnicas.
- [`docs/imagekit-cdn.md`](docs/imagekit-cdn.md) — configuração da CDN.
- [`docs/diagrama/`](docs/diagrama/) — diagrama da arquitetura.
- [`evidencias/`](evidencias/) — capturas de tela do painel.
- `.env.infra.example` — modelo das variáveis (segredos ficam em `.env.infra`, fora do git).

Ordem de execução (referência): `01-vpc` → `02-subnets` → `03-security` →
`04-compute` → `05-public-ip` → `06-dbaas` → `07-storage`. Remoção: `99-teardown`.

## Notas técnicas (achados reais)

- **DBaaS em `br-se1-b`:** a criação em `br-se1-a` retornou "Erro ao Provisionar Rede"
  na conta trial; a instância subiu em `br-se1-b` (mesma região). O banco é privado por
  padrão (IP em rede gerenciada da Magalu, sem IP público).
- **SSH (porta 22) bloqueado** na conta trial: o `sg-web` expõe apenas HTTP/HTTPS —
  superfície de entrada mínima. O SSH restrito ao IP do admin é o desenho pretendido.
- **Firewall = Security Groups** com negação implícita (só passa o que é liberado).
- **Bucket privado + CDN:** o público acessa as imagens só pela CDN, que lê o bucket privado via credencial S3.

## Segredos

Senha do banco e chaves do Object Storage ficam em `.env.infra`, fora do controle de
versão (ver `.env.infra.example`).

## Custos e limpeza

VM, IP público e DBaaS geram cobrança enquanto ativos. Ao terminar, executei
`infra/99-teardown.sh` para não consumir o saldo.
