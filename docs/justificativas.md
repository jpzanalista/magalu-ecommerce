# Justificativas Técnicas

> Respostas às 5 questões da atividade.

## 1. Por que o banco de dados foi colocado na sub-rede privada?
Porque o banco guarda os dados mais sensíveis (clientes, pedidos) e não deve ficar
exposto à internet. Na arquitetura, o DBaaS PostgreSQL **não tem IP público** — só é
alcançável pela rede interna da Magalu, a partir de recursos da mesma região (a VM na
sub-rede pública). Assim, todo acesso ao banco passa obrigatoriamente pela aplicação,
nunca direto de fora. É defesa em profundidade: mesmo que a VM seja comprometida, o
banco segue isolado da internet, reduzindo a superfície de ataque.

## 2. Qual é a função do Firewall nesta arquitetura?
O Firewall (implementado como **Security Groups**) controla explicitamente o tráfego
de entrada e saída de cada recurso, aplicando o **menor privilégio**. Ele usa
"negação implícita": só passa o que há regra liberando. No projeto, o `sg-web` (VM)
libera só HTTP (80) e HTTPS (443) do público; o `sg-db` (banco) libera só a porta
5432 vinda da sub-rede da aplicação. Todo o resto é bloqueado — protegendo os
recursos e minimizando o que fica exposto.

## 3. Qual a vantagem de usar Object Storage em vez da VM para armazenar imagens?
- **Escalabilidade e durabilidade:** o Object Storage escala sem limite prático e
  replica os dados; o disco da VM é fixo e ponto único de falha.
- **Desacoplamento:** as imagens não dependem da VM estar ligada — se a VM cair ou
  for recriada, as imagens continuam disponíveis.
- **Custo:** armazenamento de objetos é mais barato por GB e você paga pelo uso.
- **Distribuição:** é compatível com S3 e integra direto com a CDN, sem sobrecarregar
  a VM servindo arquivos estáticos.

## 4. Qual o benefício da utilização da CDN?
A CDN entrega as imagens de servidores de borda próximos ao usuário, com cache.
- **Velocidade / menor latência:** a imagem vem do ponto mais próximo, não da origem.
- **Menos carga na origem:** o bucket é acessado poucas vezes; o cache serve o resto.
- **Transformações em tempo real:** no ImageKit, dá pra redimensionar e converter
  formato (ex.: WebP) pela URL (`?tr=w-300,f-webp`), entregando a imagem ideal por
  dispositivo.
- **Segurança:** o bucket fica privado e só a CDN o acessa (via credencial) — o
  público nunca toca o storage direto.

## 5. Por que informações sensíveis devem ser armazenadas em variáveis de ambiente?
Para separar segredos (senhas, chaves) do código. Se as credenciais ficassem no
código, iriam para o Git — visíveis a qualquer um e no histórico para sempre. Com
variáveis de ambiente (aqui, o arquivo `.env.infra`, que está no `.gitignore`), os
segredos ficam **fora do controle de versão** e só existem no ambiente de execução.
Isso evita vazamento no GitHub, permite valores diferentes por ambiente e facilita a
rotação de segredos. Neste projeto, a senha do banco e as chaves do Object Storage
ficam no `.env.infra`, e o repositório versiona só o `.env.infra.example` (vazio).
