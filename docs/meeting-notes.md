📌 Projeto: DuoSpend
📅 Data: 27/06/2026
🕒 Início: 15:01
🕓 Fim: em andamento
👤 Participantes: Aline + ChatGPT

---

## 🧭 Status atual do ambiente

✔ Flutter instalado  
✔ Android Studio instalado  
✔ SDK configurado  
✔ Pasta do projeto criada  

Estrutura local:

DuoSpend/
├── app/
├── assets/
├── backend/
├── design/
├── docs/
├── .gitignore
├── README.md

---

## 🎯 Objetivo da sessão

Organizar base do projeto e iniciar arquitetura profissional do DuoSpend.

---

## ✅ Decisões tomadas hoje

- O DuoSpend será um sistema com dois modos de visão:
  - 👤 Individual (minhas finanças)
  - 🏡 Compartilhado (casal)

- O projeto será tratado como produto real com:
  - documentação viva
  - roadmap
  - changelog
  - backlog
  - versionamento

- Todas as mudanças serão registradas com data e hora.

---

## 🧱 Estrutura oficial definida

- `app/` → Flutter (frontend)
- `backend/` → serviços futuros (Firebase/API)
- `docs/` → documentação do produto
- `design/` → UI, wireframes, identidade visual
- `assets/` → imagens, fontes, ícones
- `CHANGELOG.md` → histórico de versões
- `README.md` → visão pública do projeto

---

## 💡 Ideias registradas hoje

- Modo Julgador (humor)
- Modo Analista (neutro)
- Modo Sincerão
- Modo Motivador

- Captura de gastos com mínimo esforço (visão principal do produto)

- Sistema de dupla visão:
  - pessoal
  - casal

---

## 🚧 Próximo passo imediato

👉 Criar estrutura inicial do Flutter dentro da pasta `/app`

👉 Definir arquitetura base (Feature-first)

👉 Conectar projeto ao Git (controle de versão)

---

## ⏭ Próxima decisão importante

- Definir stack do backend (Firebase vs custom API)
- Definir design system inicial
- Criar primeira tela (Home ou Auth)

---

## 🧠 Observação técnica

Este projeto já está sendo tratado como software em nível de produto:

- com versionamento
- documentação viva
- backlog estruturado
- arquitetura definida antes do código


📅 Sprint 2 — Arquitetura do DuoSpend

📅 Data: 27/06/2026
🕒 Início: 19:00
🎯 Objetivo: Criar a arquitetura definitiva do projeto.

Tempo estimado: 45 a 60 minutos.

🎯 Antes de criar qualquer pasta

Eu quero relembrar os pilares do DuoSpend.

👤 Área Individual

Cada usuário terá:

Dashboard pessoal
Carteiras (futuramente)
Receitas
Despesas
Metas pessoais
Relatórios pessoais

Esses dados pertencem somente ao usuário.

❤️ Área do Casal

Será um espaço compartilhado.

Os dois terão acesso aos mesmos dados:

Gastos compartilhados
Receitas compartilhadas (se houver)
Metas do casal
Relatórios do casal
Saldo conjunto
🔐 Login

Cada pessoa terá sua própria conta.

Exemplo:

Aline
        \
         \
          ❤️ Duo
         /
        /
João

Não existe "login do casal".

Existem duas contas ligadas a um mesmo espaço compartilhado.

Essa decisão é excelente e facilita recursos futuros, como remover um membro do casal sem apagar os dados do outro.

## Sprint 2 — Arquitetura

### Concluído

- Documento de arquitetura criado (`docs/architecture.md`)
- Definida arquitetura Feature First
- Definida separação entre área Individual e Casal
- Firebase definido como backend oficial
19:40

## Sprint 3 — Design System (CONCLUÍDA)
 Objetivo

Criar a identidade visual base do DuoSpend e padronizar o estilo do app.

✅ O que foi feito
Estrutura core/ criada
Estrutura de pastas base definida
Definição da arquitetura Feature First
Criação da identidade visual inicial do app
Definição da personalidade do produto:
Calmo + Profissional (A + B)
Criação do AppColors
Definição do padrão visual:
Azul como cor primária
Roxo como área de casal
Verde para sucesso
Laranja para alerta
Vermelho para erro
Criação da primeira tela de UI (Login base)
Definição da Home com visão Individual + Casal
Definição de comportamento da Home (dinâmica)
Criação de documentação:
architecture.md
conventions.md (ou iniciado)
meeting-notes.md
Definição de padrão de commits por sprint
Definição de fluxo de desenvolvimento do produto
🧠 Decisões importantes da Sprint 3
O DuoSpend terá identidade própria (não “template Flutter”)
O app será:
calmo
organizado
leve visualmente
Área individual + área casal coexistem
Home será dinâmica (usuário escolhe o foco)
Design System será base de todas as telas futuras
📦 Resultado da Sprint 3

👉 O app agora tem:

Base visual definida
Arquitetura preparada
Estrutura escalável
Direção clara de produto

## Sprint 4 — Autenticação (INICIANDO AGORA)
🎯 Objetivo

Fazer o usuário entrar no DuoSpend com Google (Firebase Auth) e preparar sessão persistente.

📌 Resultado esperado no final da sprint

O usuário:

Abre o app
Vê tela de login
Clica “Entrar com Google”
Autentica
Vai para Home automaticamente
Se fechar o app → continua logado
inciando 20:30
fechado ás 1



## Sprint 5 — Integração com Firebase e Primeiras Funcionalidades

Objetivo da Sprint:
Transformar a Home estática em uma Home funcional, conectando o DuoSpend ao Firebase Firestore e permitindo o gerenciamento das primeiras transações.

📌 História 5.1 — Persistência do Usuário
Objetivo

Criar automaticamente um registro do usuário no Firestore após o primeiro login com Google.

Critérios de aceite
Login realizado com sucesso.
Documento criado em users/{uid}.
Armazenar:
UID
Nome
E-mail
Foto de perfil
Data de criação
Em logins futuros, reutilizar o documento existente.
📌 História 5.2 — Carteira Principal
Objetivo

Criar automaticamente uma carteira padrão para novos usuários.

Critérios de aceite
Criar coleção wallets.
Criar carteira "Principal".
Saldo inicial = R$ 0,00.
Associar ao usuário logado.
📌 História 5.3 — Tela Nova Transação
Objetivo

Criar a primeira tela de cadastro de movimentações.

Campos
Tipo (Receita/Despesa)
Valor
Categoria
Data
Observação
Critérios de aceite
Validação dos campos obrigatórios.
Layout seguindo o padrão visual do DuoSpend.
📌 História 5.4 — Salvar Transações
Objetivo

Persistir movimentações no Firestore.

Critérios de aceite

Cada transação deverá conter:

ID
Usuário
Carteira
Tipo
Valor
Categoria
Data
Observação
Timestamp
📌 História 5.5 — Atualização Automática da Home
Objetivo

Substituir dados estáticos por informações reais.

Atualizar automaticamente
Saldo Total
Receitas
Despesas
Últimas movimentações

Sempre que uma transação for criada.

📌 História 5.6 — Persistência dos Dados
Objetivo

Garantir que os dados permaneçam após fechar o aplicativo.

Critérios de aceite
Fechar o app.
Abrir novamente.
Recuperar dados do Firestore.
Exibir saldo e movimentações corretamente.
🎯 Resultado esperado da Sprint

Ao final da Sprint 5, o usuário deverá conseguir:

✅ Fazer login com Google.
✅ Ter seu perfil criado automaticamente.
✅ Receber uma carteira padrão.
✅ Adicionar receitas e despesas.
✅ Ver o saldo atualizado em tempo real.
✅ Visualizar as últimas movimentações.
✅ Fechar e reabrir o aplicativo mantendo todos os dados.
⏱️ Estimativa

Sprint 5 — Firebase + Primeiras Funcionalidades

Estimativa: 8 a 12 horas de desenvolvimento, considerando testes e ajustes.
tempo: 4horas


## Sprint 6 — Home Dinâmica (Firestore)

Objetivo: substituir os dados fixos da Home por dados reais do Firebase Firestore.

📌 Back-end
Criar WalletRepository
Implementar leitura da carteira principal do usuário
Criar método para obter saldo
Criar método para obter nome da carteira
Preparar repositório para futuras múltiplas carteiras
📌 Front-end
Buscar dados do usuário logado
Exibir nome do usuário na Home
Exibir foto do perfil do Google
Exibir nome da carteira principal
Exibir saldo real da carteira
Remover valores fixos (hardcoded)
📌 Estrutura
features/
└── home/
    ├── data/
    │   └── repositories/
    │       └── wallet_repository.dart
    │
    ├── presentation/
    │   ├── pages/
    │   │   └── home_page.dart
    │   └── widgets/
    │       ├── balance_card.dart
    │       ├── wallet_card.dart
    │       └── ...
📌 Resultado esperado

Após o login, a Home deverá mostrar automaticamente:

👋 Nome do usuário
📷 Foto do perfil
👛 Carteira Principal
💰 Saldo da carteira (Firestore)
🎯 Meta da Sprint

Ao finalizar esta sprint, o DuoSpend deixará de utilizar dados estáticos na tela inicial e passará a consumir informações reais armazenadas no Firebase Firestore, estabelecendo a base para receitas, despesas e sincronização em tempo real nas próximas sprints.

## Sprint 7 – Cadastro de Transações

Objetivo: Implementar o cadastro e gerenciamento das primeiras movimentações financeiras do DuoSpend.

Back-end
Criar TransactionModel.
Criar TransactionRepository.
Estruturar a coleção transactions no Firestore.
Salvar receitas e despesas vinculadas ao usuário.
Front-end
Criar tela Nova Transação.
Abrir a tela pelo botão + da Home.
Formulário com:
Tipo (Receita ou Despesa)
Valor
Descrição
Data
Carteira
Validação dos campos obrigatórios.
Regras de Negócio
Atualizar automaticamente o saldo da carteira ao salvar uma transação.
Receitas aumentam o saldo.
Despesas diminuem o saldo.
Registrar data e hora da movimentação.
Home
Listar as últimas transações cadastradas.
Atualizar saldo da carteira em tempo real.
Atualizar os cards de Receitas e Despesas.
Meta da Sprint

Ao final desta Sprint, o usuário deverá conseguir:

Fazer login.
Cadastrar uma receita.
Cadastrar uma despesa.
Ver o saldo da carteira atualizado automaticamente.
Visualizar as movimentações recentes na tela inicial.
Tempo estimado

≈ 4 a 6 horas de desenvolvimento, dependendo dos ajustes de UI e validações.

🚀 Essa é uma das sprints mais importantes do projeto, porque a partir dela o DuoSpend deixa de ser apenas uma estrutura e passa a funcionar como um gerenciador financeiro de verdade.

começando 17:36
parando 18:10
começando 20:25
parando 21:10
começando 23:05
terminando 23:15

## Sprint 7.5 — Integração da Home com Transações

Data: 01/07/2026

Objetivo

Conectar a Home ao Firestore para que receitas, despesas e histórico deixem de ser estáticos e passem a refletir os dados reais do usuário.

O que será desenvolvido
📌 Buscar transações do Firestore
Criar método para listar transações do usuário
Ordenar por data
Disponibilizar os dados para a Home
📌 Atualizar SummaryCard

Calcular automaticamente:

💚 Total de Receitas
❤️ Total de Despesas
📌 Atualizar TransactionsPreview

Exibir as últimas transações cadastradas.

Exemplo:

Mercado
Salário
Uber
Pix
Gasolina
📌 Atualização automática

Ao salvar uma nova transação:

atualizar saldo;
atualizar receitas;
atualizar despesas;
atualizar histórico;

sem precisar reiniciar o aplicativo.

Resultado esperado

A Home passa a ser totalmente alimentada pelos dados do Firestore, exibindo informações reais do usuário em tempo real.
começando: 23:33
parando: 23:58

## ## Sprint 8 — Refatoração da Base

📅 Data: 02/07/2026

🎯 Objetivo

Consolidar a arquitetura do DuoSpend antes da implementação das próximas funcionalidades, reduzindo dívida técnica, padronizando o projeto e preparando a base para crescimento.

---

História 8.1 — Auditoria Técnica

Objetivo

Realizar uma auditoria completa do projeto para identificar:

• arquivos duplicados;
• código morto;
• widgets não utilizados;
• imports desnecessários;
• oportunidades de refatoração;
• aderência à arquitetura Feature First.

Critérios de aceite

- Projeto auditado.
- Lista de melhorias documentada.
- Dívida técnica registrada.

---

História 8.2 — Padronização da Home

Objetivo

Remover informações fixas e tornar a Home totalmente dinâmica.

Itens

- Nome do usuário obtido pelo Firebase.
- Foto do usuário.
- Mensagens padronizadas.
- Componentes reutilizáveis.

Critérios de aceite

A Home não deve conter dados hardcoded.

---

História 8.3 — Padronização Visual

Objetivo

Centralizar cores, textos e estilos.

Itens

- AppColors
- AppTextStyles
- AppStrings

Critérios de aceite

Nenhuma tela deverá utilizar cores fixas fora do Design System.

---

História 8.4 — Organização do Projeto

Objetivo

Consolidar a estrutura do projeto.

Itens

- revisão das pastas;
- revisão dos imports;
- remoção de arquivos desnecessários;
- documentação da arquitetura.

---

História 8.5 — Documentação

Objetivo

Criar a documentação oficial do DuoSpend.

Arquivos

01 - Contexto Geral.md
02 - Visão do Produto.md
03 - PRD.md
04 - Roadmap.md
05 - Arquitetura.md
06 - Design System.md
07 - Regras de Negócio.md
08 - Backend.md
09 - Flutter.md
10 - Changelog.md
README - IA.md

---

Resultado esperado

Ao final da Sprint 8 o DuoSpend deverá possuir:

✅ Arquitetura consolidada

✅ Projeto padronizado

✅ Home organizada

✅ Design System centralizado

✅ Documentação oficial

✅ Base preparada para as próximas funcionalidades

---

⏱️ Estimativa

6 a 10 horas

Início:
02/07/2026
17:09
parei 17:30
retornando 22:34

## Sprint 8 - Status Atual
História 8.1 — Auditoria Técnica
✅ Controller duplicado removido
✅ Widget duplicado removido
✅ TransactionModel duplicado removido
✅ UserModel movido para Auth
✅ UserRepository movido para Auth
✅ Arquitetura mais coerente
História 8.2 — Home
✅ Nome do usuário dinâmico
✅ Primeiros elementos do Design System aplicados
História 8.3 — Design System
✅ AppSpacing criado
✅ Home utilizando AppSpacing
✅ Primeira cor centralizada (AppColors.textSecondary)

conclusao: 00:51

## 🧠 Sprint 9 — Knowledge Engine

📅 Data: 03/07/2026

🎯 Objetivo

Transformar o DuoSpend em um sistema capaz de aprender com os dados do usuário, centralizando todo o conhecimento do domínio em uma camada reutilizável.

História 9.1 — Knowledge Layer
Objetivo

Criar a estrutura base da camada de conhecimento.

Estrutura:

shared/
   knowledge/
      classifier/
      products/
      merchants/
      taxonomy/
      learning/
      insights/

Critérios de aceite

Estrutura criada
Organização documentada
História 9.2 — Product Repository

Objetivo

Centralizar todas as operações relacionadas aos produtos.

Critérios

Buscar produto
Buscar por nome
Buscar por código de barras
Salvar produto
Atualizar produto
História 9.3 — Merchant Repository

Objetivo

Centralizar estabelecimentos.

Critérios

Cadastro
Busca
Favoritos
Histórico
História 9.4 — Product Autocomplete

Objetivo

Enquanto o usuário digita:

Hei...

o Duo sugere

🍺 Heineken

Critérios

Busca instantânea
Sugestão
Seleção
História 9.5 — Suggestion Engine

Objetivo

Preencher automaticamente:

unidade
categoria
subcategoria
marca

Critérios

Sem IA.

Somente conhecimento.

História 9.6 — Learning Engine

Objetivo

Aprender com as correções do usuário.

Exemplo

Usuário altera

Heineken

↓

Bebidas Premium

O Duo passa a sugerir isso futuramente.

História 9.7 — Insight Engine

Objetivo

Gerar conhecimento.

Exemplos

preço médio
último preço
consumo
comparação
tendências
Resultado esperado

Ao final da Sprint 9:

✅ Base de conhecimento criada

✅ Produtos reutilizáveis

✅ Estabelecimentos reutilizáveis

✅ Sugestões inteligentes

✅ Aprendizado contínuo

✅ Base preparada para IA Premium

Estimativa

12 a 18 horas
comecei: 00:21
parei: 01:50


comecei 22:20
terminei: 23:40

## Sprint 10
Estado atual do projeto

Finalizamos a Sprint 9.

Arquitetura concluída
Flutter organizado em Features.
Firebase configurado.
Wallet funcionando.
Transaction funcionando.
Histórico funcionando.
ProductModel criado.
TransactionItemModel refatorado.
ProductRepository criado.
ProductMemory criado.
ProductSeed criado.
ProductSummaryCard criado.
ProductSearchField funcionando.
Autocomplete funcionando.
Produto conhecido é reconhecido automaticamente.
Preenchimento automático de:
nome
marca
unidade
categoria
subcategoria
Separação iniciada entre:
Categoria Financeira
Categoria do Produto
Projeto compilando.
Flutter Analyze sem erros.
Objetivo da Sprint 10

Transformar o DuoSpend de um formulário financeiro para uma experiência de compra inteligente.

O usuário não registra "transações".

O usuário registra "compras".

Toda a UX será construída pensando nisso.

Sprint 10
10.1 — Purchase Experience

Refatorar a tela Nova Compra.

Fluxo esperado:

Onde comprou?

↓

O que comprou?

↓

Produto reconhecido

↓

Quantidade

↓

Quanto pagou?

↓

Adicionar outro produto

↓

Resumo da compra

↓

Salvar compra
10.2 — Merchant Intelligence

Criar:

MerchantModel

Campos iniciais:

id
name
normalizedName
merchantType
city
state
favorite
createdAt
updatedAt

Criar:

MerchantRepository
MerchantMemory
MerchantSeed
MerchantSearchField

Autocomplete para:

Condor
Festval
Muffato
Assaí
Atacadão
iFood
Shell
Droga Raia
10.3 — Purchase Summary

Criar um card fixo na parte inferior.

Mostrar:

Itens

Total

Mercado

Economia futura

Atualização em tempo real.

10.4 — Multi Item Experience

Permitir adicionar diversos produtos.

Exemplo:

🍺 Heineken

🥩 Picanha

🥤 Coca

🥛 Leite

Sem sair da tela.

10.5 — Product Intelligence

Cada item passa a armazenar:

categoria do produto
marca
unidade
preço médio
último preço
último estabelecimento

Preparar para memória permanente.

10.6 — Merchant Memory

Ao salvar uma compra:

Atualizar automaticamente:

último preço
última compra
frequência
estabelecimento
10.7 — AI Foundations

Preparar arquitetura para:

OCR de nota fiscal
IA classificadora
Sugestões automáticas
Insights financeiros
Histórico inteligente

Ainda sem IA generativa.

Somente infraestrutura.

10.8 — UX

Remover qualquer aparência de formulário.

Meta:

Parecer um aplicativo moderno.

Inspirar-se em:

iFood
Nubank
Splitwise
Todoist
Apple Wallet

Poucos campos.

Muito contexto.

Pouca digitação.

Decisões de arquitetura

Separar definitivamente:

Categoria Financeira

Responde:

Onde o dinheiro foi gasto?

Exemplos:

Alimentação
Transporte
Saúde
Lazer
Casa
Categoria do Produto

Responde:

O que é este produto?

Exemplos:

Bebidas
Carnes
Laticínios
Limpeza
Higiene
Pets
Merchant

Responde:

Onde foi comprado?

Exemplos:

Mercado
Farmácia
Restaurante
Delivery
Posto
Próximo grande objetivo

O DuoSpend deixará de ser apenas um controle financeiro.

Ele será um assistente inteligente de compras, capaz de lembrar produtos, preços, mercados e hábitos de consumo, reduzindo a quantidade de informações que o usuário precisa digitar e oferecendo insights úteis ao longo do tempo.


Sprint 10

- Merchant Intelligence V1
- Merchant Memory
- PurchaseService
- SavePurchaseUseCase
- Nova arquitetura de compras
- Categoria automática
- Resumo automático
- UX Nova Compra
- Merchant aprende novos estabelecimentos
comecei 23:41
terminei 02:00

## Sprint 11 — Purchase Domain & Product Memory

📅 Data: 04/07/2026

🕒 Início: 
⏸️ Pausa: 
▶️ Retorno: 
🏁 Fim: 
⏱️ Tempo efetivo: 

---

## 🎯 Objetivo da Sprint

Consolidar o domínio de compras do DuoSpend e iniciar a memória inteligente de produtos.

A Sprint 10 transformou a tela de Nova Compra em uma experiência moderna e criou a Merchant Intelligence V1.

Agora a Sprint 11 vai separar melhor o conceito de Compra, fortalecer a arquitetura de domínio e começar a preparar o DuoSpend para lembrar produtos, preços, frequência e relação entre produto e estabelecimento.

---

## 🧠 Estado atual do projeto

Finalizamos a Sprint 10 com:

✅ Nova Compra reformulada  
✅ Compra sempre tratada como despesa  
✅ MerchantSelectorCard funcionando  
✅ MerchantModel criado  
✅ MerchantTypes criado  
✅ MerchantSeed criado  
✅ MerchantRepository criado  
✅ MerchantMemoryModel criado  
✅ MerchantMemoryRepository criado  
✅ PurchaseService criado  
✅ SavePurchaseUseCase criado  
✅ Merchant manual funcionando  
✅ Merchant Memory funcionando  
✅ Lojas novas reaparecendo como sugestão  
✅ Categoria financeira detectada automaticamente  
✅ Bottom Sheet para editar categoria  
✅ Resumo automático da compra  
✅ Valor total calculado pelos itens  
✅ Flutter Analyze sem erros  
✅ App compilando  

---


## Sprint 11

Até agora, a persistência ainda usa `TransactionModel`, mas a experiência do usuário já é de Compra.

A Sprint 11 inicia a consolidação oficial do domínio:

Compra ≠ Transação

A compra é o evento de consumo.

A transação é o impacto financeiro gerado por esse evento.

Fluxo conceitual:

Purchase
  ↓
gera Transaction
  ↓
atualiza Wallet
  ↓
atualiza Merchant Memory
  ↓
atualiza Product Memory
📌 Histórias da Sprint 11
11.1 — Purchase Domain

Criar a base do domínio de compras.

Arquivos previstos:

features/purchases/
  domain/
    models/
      purchase_model.dart
      purchase_summary_model.dart

Objetivo:

Representar uma compra como entidade própria, mesmo que a persistência continue usando TransactionModel por enquanto.

Critérios de aceite:

Criar PurchaseModel.
Criar PurchaseSummaryModel.
Manter compatibilidade com TransactionModel.
Não quebrar histórico, wallet ou tela atual.
11.2 — Purchase Controller

Criar um controller específico para a experiência de compra.

Objetivo:

Reduzir dependência do TransactionController.

Critérios de aceite:

Criar PurchaseController.
Mover estado temporário da compra para ele.
Gerenciar:
merchant selecionado;
itens;
valor manual;
categoria financeira;
subcategoria financeira;
total calculado.
Preparar a tela para deixar de usar TransactionController.
11.3 — Product Memory V1

Criar memória permanente de produtos.

Objetivo:

O DuoSpend deve começar a lembrar produtos comprados, valores, quantidade e estabelecimento.

Estrutura esperada:

features/products/
  domain/
    product_memory_model.dart
  data/
    product_memory_repository.dart

Campos iniciais:

productId
productName
brand
category
subcategory
unit
timesPurchased
totalQuantity
totalSpent
averagePrice
lastPrice
lastMerchantId
lastMerchantName
lastPurchaseAt

Critérios de aceite:

Ao salvar uma compra, atualizar memória dos produtos.
Registrar último preço.
Registrar estabelecimento.
Calcular preço médio.
Incrementar frequência de compra.
11.4 — Integração Product Memory com SavePurchaseUseCase

Objetivo:

O SavePurchaseUseCase deve atualizar:

Transaction
Wallet
Merchant Memory
Product Memory

Critérios de aceite:

Cada item da compra alimenta ProductMemoryRepository.
O use case continua sendo o único ponto de orquestração da compra.
A UI não conhece Product Memory diretamente.
11.5 — Purchase Suggestions Foundation

Objetivo:

Preparar a base para sugestões futuras.

Exemplo futuro:

Você costuma comprar estes produtos no Condor:
- Arroz
- Leite
- Café

Nesta sprint, ainda não precisa exibir sugestões na tela.

Critérios de aceite:

Product Memory gravada corretamente.
Dados suficientes para gerar sugestões futuras.
Arquitetura preparada para PurchaseSuggestionService.
11.6 — Refatoração da Nova Compra

Objetivo:

Deixar a NewTransactionPage mais próxima de uma futura NewPurchasePage.

Critérios de aceite:

Reduzir responsabilidade da tela.
Avaliar renomeação futura.
Manter app compilando.
Não quebrar UX criada na Sprint 10.
🧪 Testes da Sprint 11
Teste 1 — Compra com merchant conhecido
Selecionar Condor.
Adicionar produtos.
Salvar compra.
Validar:
histórico;
saldo;
merchant memory;
product memory.
Teste 2 — Compra com merchant novo
Digitar um mercado novo.
Salvar compra.
Abrir nova compra.
Validar merchant reaparecendo como sugestão.
Validar produtos salvos na memória.
Teste 3 — Produto recorrente
Comprar o mesmo produto duas vezes.
Validar:
timesPurchased;
averagePrice;
lastPrice;
lastMerchantName.
Teste 4 — Integridade
Rodar flutter analyze.
Rodar flutter run.
Confirmar que Home, Histórico, Wallet e Nova Compra continuam funcionando.
🎯 Resultado esperado da Sprint 11

Ao final da Sprint 11, o DuoSpend deverá:

✅ Ter domínio de compras iniciado
✅ Ter PurchaseModel e PurchaseSummaryModel
✅ Ter PurchaseController planejado ou iniciado
✅ Ter Product Memory V1 funcionando
✅ Atualizar memória de produtos ao salvar compras
✅ Manter Merchant Memory funcionando
✅ Manter Wallet e Histórico funcionando
✅ Estar preparado para sugestões inteligentes na Sprint 12

⏱️ Estimativa

Sprint 11 — Purchase Domain & Product Memory

Estimativa: 4 a 6 horas de desenvolvimento.

🧭 Próximo grande objetivo

A partir da Sprint 11, o DuoSpend começa a aprender não só onde o usuário compra, mas também o que ele compra, quanto paga e com que frequência.

Isso prepara o app para:

lista de compras inteligente;
sugestões por estabelecimento;
comparação de preços;
controle de consumo;
OCR de nota fiscal;
IA de recomendações futuras.

começando 13:30
parando 14:47
voltei 14:56
parando 15:53
voltando 16:50
terminei 17:40


## Sprint 12
Shopping Intelligence

Status: Planejada
Estimativa: 6 a 8 horas
Objetivo: criar a base da Lista Inteligente do DuoSpend, conectando compras, produtos recorrentes e sugestões futuras.

Escopo da Sprint 12
Criar domínio Shopping
Criar ShoppingItemModel
Criar ShoppingListModel
Criar ShoppingRepository
Criar FirebaseShoppingRepository
Criar ShoppingController
Preparar integração com PurchaseFlow
Criar base para Lista Inteligente
Criar primeiros conceitos de recompra automática
Preparar arquitetura para consumo doméstico/premium
Decisão de Produto

A Lista Inteligente será baseada em baixa digitação.

O usuário não precisa registrar tudo manualmente. O DuoSpend deve aprender com o histórico de compras e sugerir itens recorrentes.

Ideia Premium registrada

Criar futuramente o módulo de Casa Inteligente / Consumo Doméstico, com:

botão “Acabou”
cálculo de duração de produtos
sugestão automática de recompra
controle simples de estoque
previsões de consumo

Regra importante: isso será opcional, não obrigatório.
comecei: 17:30
pausei: 18:40

## Sprint 13 — Product Intelligence (Motor de Conhecimento)

Objetivo

Iniciar o Product Intelligence, o núcleo responsável por fazer o DuoSpend entender produtos, em vez de apenas armazenar nomes.

Esta Sprint marca a transição da arquitetura para um modelo orientado a conhecimento, preparando o sistema para reconhecer produtos equivalentes, aprender hábitos de compra e alimentar automaticamente todos os módulos inteligentes do aplicativo.

Objetivos da Sprint
Arquitetura

Criar o novo módulo:

features/
└── product_intelligence/

seguindo Clean Architecture:

domain/
data/
presentation/
Product Identity

Criar a identidade canônica dos produtos.

O DuoSpend deverá reconhecer que:

Leite Tirol Integral 1L
Leite Italac Integral 1L
Leite Parmalat Integral

representam:

Produto Base:
Leite

mantendo separadamente:

marca
variação
volume
unidade
categoria
subcategoria
Product Intelligence Service

Criar o serviço responsável por responder perguntas como:

Esses dois produtos representam o mesmo item?
Qual é o produto canônico?
Quais marcas o usuário costuma comprar?
Existe alguma marca favorita?
Qual categoria esse produto pertence?
Quais variações já foram compradas?
Esse produto costuma ser recorrente?
Existe algum possível substituto?
Product Identity Model

Criar o modelo responsável por representar um produto independentemente da forma como ele foi digitado.

Exemplo:

Produto:
Leite

Marcas conhecidas:
- Tirol
- Italac
- Parmalat

Variações:
- Integral
- Desnatado
- Zero Lactose

Volumes:
- 500 ml
- 1 L
- 2 L
Shopping Suggestion

Preparar a geração de sugestões inteligentes utilizando:

Product Memory
Purchase History
Merchant Intelligence
Product Intelligence
Estrutura preparada para IA

A arquitetura deverá permitir que, futuramente, modelos de IA apenas alimentem o Product Intelligence, sem necessidade de alterar:

Controller
Flow
UI
Resultado esperado

Ao final da Sprint o DuoSpend começará a possuir conhecimento sobre produtos, permitindo futuramente:

reconhecimento automático de produtos equivalentes;
agrupamento de marcas;
agrupamento de variações;
previsão de reposição;
sugestões inteligentes de compras;
comparação de preços entre marcas;
aprendizado contínuo dos hábitos da residência.
Filosofia da Sprint

O DuoSpend deixa de pensar em:

Compras

e passa a pensar em:

Conhecimento

A compra passa a ser apenas um evento.

O conhecimento adquirido sobre aquele produto passa a ser permanente e reutilizado por todo o sistema.

Próximos módulos beneficiados

O Product Intelligence servirá como base para:

Shopping Intelligence
Merchant Intelligence
Consumption Intelligence
Household Intelligence
Análises financeiras
Alertas de economia
Recomendações automáticas
IA do DuoSpend
Objetivo arquitetural

Transformar o DuoSpend em um sistema capaz de aprender como a casa funciona, reduzindo ao máximo a quantidade de informações que o usuário precisa informar manualmente.

Princípio do projeto: O DuoSpend deve pedir pouco e aprender muito. 🚀
iniciando:17:30
concluída: 18:48

## Sprint 14 — Knowledge Integration
Objetivo

Integrar o Product Knowledge ao restante do DuoSpend, tornando o motor de conhecimento parte real do fluxo da aplicação.

14.1 — Bootstrap da Inteligência

Objetivo:

Criar a camada responsável por montar o Knowledge Engine.

Entregas:

KnowledgeModule
Bootstrap do ProductMemoryRepository
Bootstrap do ProductIntelligenceEngine
Bootstrap do ProcessProductIntelligenceUseCase
14.2 — Dependency Injection

Objetivo:

Remover qualquer instanciação manual.

Entregas:

ShoppingFlow recebe UseCases injetados
Knowledge recebe Repository injetado
Preparação para GetIt/Riverpod futuramente
14.3 — Integração com Shopping

Objetivo:

Toda criação de item passa pelo Knowledge Engine.

Fluxo:

Usuário

↓

ShoppingController

↓

ShoppingFlowService

↓

ProcessProductIntelligenceUseCase

↓

Knowledge Engine

↓

ShoppingRepository
14.4 — Primeira Aprendizagem Real

Objetivo:

Quando um produto novo aparecer:

Leite Tirol Zero Lactose

o DuoSpend deverá:

classificar
procurar
aprender
salvar
continuar o fluxo

Tudo automaticamente.

14.5 — Persistência da Memória

Hoje:

RAM

Preparar para:

Hive
SQLite
Firebase

sem alterar o domínio.

14.6 — Testes

Criar testes para:

ProductClassifier
ProductMatcher
ProductLearningEngine
ProductIntelligenceEngine
ProductKnowledgeLoader
14.7 — Refatoração

Revisar:

nomenclaturas
responsabilidades
imports
dependências
SOLID
Clean Architecture
Resultado esperado

Ao final da Sprint 14 teremos:

Shopping

↓

Knowledge Engine

↓

Aprende sozinho

↓

Salva conhecimento

↓

Repository

↓

Shopping Repository

Pela primeira vez o DuoSpend começará realmente a aprender com o usuário.

Tempo estimado

6–8 horas

Risco

🟢 Baixo

Todo o domínio foi construído na Sprint 13.

Agora é integração.

iniciando 18:50
terminando 19:39

## Sprint 15 — Self Learning Engine

Status: Planejada

Objetivo:

Transformar a Knowledge Foundation em um sistema que aprende automaticamente a cada compra realizada.

Entregas
1. Product Memory Evolution
Persistência do ProductMemory
Histórico de produtos aprendidos
Histórico de marcas
Histórico de embalagens
Histórico de categorias
2. Automatic Learning

Após cada cadastro de produto:

ShoppingFlow
        ↓
Knowledge Engine
        ↓
Learning Engine
        ↓
ProductMemoryRepository

O aprendizado passa a ser automático.

3. Frequency Engine

Registrar:

quantidade de compras
última compra
primeira compra
frequência
intervalo médio
4. Brand Intelligence

Exemplo:

Leite Tirol
Leite Parmalat
Leite Aurora

↓

Produto:
Leite

Marcas conhecidas:

• Tirol
• Parmalat
• Aurora
5. Package Intelligence

Aprender automaticamente:

1L
500ml
5kg
12 unidades
6. Product Graph

Cada produto passa a armazenar conhecimento como:

Produto

↓

Categoria

↓

Marcas

↓

Embalagens

↓

Sinônimos

↓

Histórico
7. Automatic Suggestions Foundation

Preparar a base para:

produtos frequentes
produtos favoritos
compras recorrentes
previsão de compra
Critérios de aceite
ProductMemory evolui automaticamente.
Frequência incrementa.
Marca passa a ser conhecida.
Embalagem passa a ser conhecida.
Histórico cresce sozinho.
Nenhuma tela precisa conhecer a Learning Engine.
Resultado esperado

Ao final da Sprint 15 o DuoSpend deixa de apenas reconhecer produtos e passa a aprender continuamente, construindo uma base de conhecimento personalizada para cada usuário.

Começando: 20:30
pausei: 20:49
começando: 22:45
terminando: 23:45


## Sprint 16 — Learning Scopes (Individual • Compartilhado • Casa • Família)
Objetivo

Evoluir a inteligência do DuoSpend para que o aprendizado deixe de ser único e passe a considerar o contexto da compra.

A partir desta Sprint, a IA começa a entender que um mesmo produto pode possuir comportamentos completamente diferentes dependendo do escopo em que foi comprado.

Exemplos:

leite comprado para mim
leite comprado para o casal
leite comprado para a casa
leite comprado para um filho

Cada um passa a possuir memória própria.

Problema atual

Hoje toda compra alimenta praticamente a mesma memória.

Isso funciona...

...até que o mesmo produto seja comprado em contextos diferentes.

Exemplo:

Aline compra café premium para ela.

Depois compra café tradicional para a casa.

Se tudo virar apenas "café", a IA aprende errado.

Outro exemplo:

Arroz compartilhado dura 18 dias.

Arroz individual dura 45 dias.

São padrões completamente diferentes.

Objetivo da Sprint

Criar uma camada de escopos de aprendizado.

Todo aprendizado deverá passar a responder:

"Quem está aprendendo isso?"

e não apenas

"O que foi comprado?"

Escopos oficiais
Individual

Memória exclusiva do usuário.

Exemplo:

minhas marcas favoritas
meus horários
minhas categorias
meus gastos
Compartilhado

Representa o casal.

Aprende:

hábitos em conjunto
compras divididas
consumo do casal
Casa

Representa tudo que pertence ao ambiente doméstico.

Exemplo:

papel higiênico

detergente

arroz

óleo

energia

água

limpeza

Família

Escopo preparado para futuras versões.

Exemplo:

fraldas

ração

remédios infantis

escola

gastos dos filhos

animais

etc.

O Cognition Core passa a pensar assim

Antes:

Compra

↓

Produto

↓

Memória

Agora:

Compra

↓

Escopo

↓

Produto

↓

Memória específica

Nova filosofia

Ao invés de aprender apenas:

leite

passa a aprender

Individual:

leite

Compartilhado:

leite

Casa:

leite

Família:

leite

Cada um com histórico próprio.

Benefícios

A IA deixa de misturar comportamentos.

Ela começa a entender que:

eu compro chocolate diferente da minha esposa

a casa consome arroz em outro ritmo

o casal compra vinho apenas em finais de semana

o cachorro possui ração própria

Novos Insights

Após esta Sprint poderão surgir perguntas como:

"Vocês estão comprando mais produtos para a casa este mês."

"Seu consumo individual de café aumentou."

"A família passou a gastar mais com alimentação."

"O consumo compartilhado diminuiu."

Estrutura prevista

Nesta Sprint será criada uma arquitetura semelhante a:

Cognition Core

    ↓

Cognition Scope

    ↓

Individual Memory

Shared Memory

House Memory

Family Memory

    ↓

Learning Engines

    ↓

Reasoning

    ↓

Predictions

    ↓

Recommendations
Inteligência futura desbloqueada

Esta Sprint prepara terreno para funcionalidades como:

Insights individuais
Insights do casal
Comparações entre pessoas
Hábitos da casa
Consumo por ambiente
IA que entende famílias
Perfis de consumo
Detecção de mudanças de rotina
Recomendações específicas por escopo
Predições independentes
Estatísticas separadas
Arquitetura

Será a primeira Sprint onde a IA começa a separar conhecimento por contexto em vez de apenas por produto.

Na prática, estamos transformando a memória em uma estrutura multidimensional.

Tempo estimado

6 a 8 horas

Resultado esperado

Ao final da Sprint 16 o DuoSpend será capaz de:

separar aprendizado por contexto
manter memórias independentes
impedir mistura de hábitos
alimentar o Cognition Core com múltiplas inteligências
preparar o terreno para insights extremamente personalizados
iniciar a verdadeira IA contextual do DuoSpend
Registro da Sprint (Meeting)

Sprint: 16 — Learning Scopes (Individual • Compartilhado • Casa • Família)

Data: 07/07/2026

Início: :

Pausa(s):

: → :

Retorno(s):

:

Término: :

Tempo bruto: ____h ____min

Tempo efetivo: ____h ____min

Status: 🟡 Em andamento

Observações:

Evolução da inteligência contextual do Cognition Core.
Introdução da arquitetura de aprendizado por escopo (Individual, Compartilhado, Casa e Família).
Base para futuras funcionalidades de insights personalizados, predições por contexto e memória multidimensional.

começando 17:10
terminando 18:16

## Sprint 16.5 — Consolidação do módulo Consumers

📅 Data: 09/07/2026

👤 Participantes: Aline + ChatGPT

🎯 Objetivo

Consolidar completamente a arquitetura do módulo Consumers, preparando a base para a Sprint 17, onde a IA começará a aprender individualmente sobre cada consumidor.

Nesta sprint não iremos evoluir a IA.

A prioridade é garantir que toda a infraestrutura do domínio Consumers esteja pronta e consistente.

✅ Situação encontrada

Durante a auditoria arquitetural da Sprint 16 foi identificado que:

Cognition Core está consistente;
ProductLearningEngine está correto;
ProductMemory está correta;
LearningEngine está correto;
Knowledge Engine está correta.

O único gargalo identificado foi o ciclo de resolução da memória, e não a arquitetura da IA.

Por esse motivo foi decidido não alterar o núcleo da inteligência nesta etapa.

Objetivos técnicos
1. Consolidar o domínio Consumers

Finalizar toda a infraestrutura do domínio.

Inclui:

Repository
Memory Repository
Models
Entities
UseCases
ciclo de persistência
2. Criar os consumidores padrão

Definir como um Wallet nasce.

Exemplo:

Wallet Nova

↓

Consumidor 1
(Eu)

Consumidor 2
(Parceiro)

ou

Consumidor único

Precisamos definir isso arquiteturalmente.

3. Ciclo de vida do Consumer

Definir:

criação
atualização
exclusão
recuperação
consumidor ativo
consumidor padrão
4. Integração com Wallet

Toda Wallet deverá conhecer seus consumidores.

Preparar:

Wallet

↓

ConsumerRepository

↓

ConsumerMemory

↓

KnowledgeContext

5. Preparar o Cognition Core

Sem alterar IA.

Apenas garantir que:

KnowledgeContext

↓

PurchaseKnowledgePayload

↓

Consumer

↓

Cognition Scope

funcionem naturalmente.

6. Eliminar acoplamentos

Verificar toda a arquitetura procurando:

dependências desnecessárias
importações erradas
responsabilidades duplicadas
7. Preparar Sprint 17

Ao terminar esta sprint devemos conseguir implementar:

"Aprender hábitos do João"

ou

"Aprender hábitos da Aline"

sem alterar arquitetura.

A Sprint 17 deverá apenas implementar algoritmos.

Critérios de conclusão

Ao final da Sprint 16.5 teremos:

✅ módulo Consumers totalmente integrado

✅ Wallet preparada para múltiplos consumidores

✅ ciclo de vida completo

✅ bootstrap preparado

✅ arquitetura limpa

✅ Cognition preparado

✅ nenhuma alteração na IA

✅ zero débito arquitetural

Resultado esperado

Ao finalizar esta sprint teremos encerrado toda a infraestrutura necessária para iniciar a inteligência individual dos usuários.

A partir da Sprint 17, o foco deixa de ser arquitetura e passa a ser comportamento inteligente, permitindo que o DuoSpend aprenda separadamente os hábitos de cada consumidor sem necessidade de novas refatorações estruturais.

⏱️ Estimativa: 3–5 horas

🎯 Meta: deixar o módulo Consumers 100% consolidado para que a Sprint 17 seja dedicada exclusivamente à evolução da inteligência do DuoSpend.

começando 18:19
terminando 19:24


## Sprint 17 — Inteligência por Consumidor

📅 Data: //2026

👤 Participantes: Aline + ChatGPT

🎯 Objetivo

Iniciar a Inteligência por Consumidor utilizando toda a infraestrutura construída nas Sprints 15, 16 e 16.5.

Nesta sprint, a IA deixará de aprender apenas sobre produtos e passará a aprender quem consome, como consome, quando consome e em qual contexto.

✅ Situação atual

Infraestrutura consolidada:

Flutter
Firebase
Wallet
Purchase Domain
Shopping Domain
Knowledge Engine
Cognition Core
Consumer Domain

Fluxo disponível:

Wallet
    │
    ▼
Consumer
    │
    ▼
Purchase
    │
    ▼
KnowledgeContext
    │
    ▼
Cognition Core

Toda a infraestrutura necessária para aprendizado individual já está pronta.

Objetivos técnicos
1. Consumer Learning Engine

Criar o mecanismo responsável por aprender hábitos individuais de consumo.

A IA deverá registrar informações como:

frequência de consumo;
produtos preferidos;
marcas favoritas;
locais de compra;
quantidades habituais;
padrões de recorrência.
2. Consumer Memory

Implementar a memória específica de cada consumidor.

Cada perfil deverá possuir histórico próprio de aprendizado.

Exemplo:

Aline
├── Café
├── Leite Integral
├── Condor
└── Compra média semanal

João
├── Coca Zero
├── Pão Integral
└── Mercado Muffato
3. Aprendizado pós-compra

Após cada compra concluída:

Compra

↓

Consumer

↓

KnowledgePayload

↓

Consumer Learning

↓

Consumer Memory

Todo aprendizado deverá continuar passando pelo Cognition Core.

4. Consumer Preferences

Criar estrutura para armazenar preferências individuais.

Exemplos:

marca favorita;
embalagem preferida;
quantidade habitual;
categoria mais consumida;
horário mais comum de compra.
5. Consumer Statistics

Criar estatísticas por consumidor.

Exemplos:

consumo médio mensal;
frequência por categoria;
intervalo médio entre compras;
ticket médio por consumidor.
6. Consumer Recommendations

Implementar recomendações individualizadas.

Exemplos:

"Aline costuma comprar leite a cada 10 dias."
"Robert provavelmente precisará de ração nesta semana."
"Marieta está próxima de consumir toda a areia."
7. Preparação para IA Conversacional

Estruturar os dados para permitir perguntas como:

"Quem costuma consumir este produto?"
"Qual produto é exclusivo da Aline?"
"Quais itens são compartilhados?"
"Quem deixou de comprar algo habitual?"
Critérios de conclusão

Ao final da Sprint 17 teremos:

✅ IA aprendendo separadamente por consumidor.

✅ Memória individual.

✅ Estatísticas individuais.

✅ Preferências individuais.

✅ Recomendações individuais.

✅ Integração completa com o Cognition Core.

✅ Zero acoplamento com interface.

Resultado esperado

Ao concluir esta sprint, o DuoSpend deixará de tratar compras apenas como eventos financeiros e passará a compreender o comportamento de consumo de cada pessoa da Wallet.

Essa evolução permitirá que futuras funcionalidades sejam personalizadas por consumidor, como previsões de reposição, recomendações inteligentes, listas automáticas de compras e análises individuais, mantendo a filosofia do projeto:

"O app deve pedir pouco e aprender muito."

⏱️ Estimativa: 5–7 horas

🎯 Meta: iniciar a Inteligência por Consumidor aproveitando integralmente a infraestrutura consolidada nas Sprints 15, 16 e 16.5, sem necessidade de novas refatorações arquiteturais.

começando 19:25
terminando 22:00

### Sprint 17.5 — Consolidação da Product Intelligence

📅 Data: 09/07/2026
🎯 Objetivo

Consolidar a inteligência de produtos do DuoSpend, garantindo que o aplicativo reutilize corretamente produtos existentes, aprenda automaticamente novos produtos cadastrados pelo usuário e mantenha a arquitetura limpa.

---

 ✅ Entregas realizadas

 Product Intelligence

* ProductRepository passou a aprender automaticamente novos produtos cadastrados pelo usuário.
* Produtos já existentes passaram a ser reutilizados corretamente durante novas compras.
* Correção da lógica de identificação de produtos ao alterar a marca.
* Alteração de marca agora cria corretamente uma nova variação do produto, sem sobrescrever o cadastro existente.

 Consumer Intelligence

* Integração consolidada com o fluxo de compras.
* Aprendizado automático preservado durante o cadastro de novos produtos.

 Nova Transação

* Tela simplificada.
* Categoria financeira automática permanece oculta quando não é necessária.
* Classificação automática passa a aparecer quando existem itens na compra.
* Melhor organização do fluxo de cadastro.

Validação

* Início da identificação visual de campos obrigatórios.
* Fluxo de criação de produtos revisado.

---

🏗 Arquitetura

Mantida integralmente:

* Clean Architecture
* SOLID
* Separação por camadas
* Repositórios independentes
* Nenhuma quebra estrutural

---

🧪 Resultado

* Reutilização correta de produtos existentes.
* Criação automática de novos produtos quando necessário.
* Cadastro de novas marcas funcionando corretamente.
* Fluxo de inteligência mais consistente.
* `flutter analyze` sem erros (apenas informações).

---

## 📌 Sprint — 17.6

Foco em UX e refinamento da experiência de cadastro de compras.

Formulário

* Padronizar campos obrigatórios com `*`.
* Melhorar visual dos campos obrigatórios.
* Revisar espaçamentos.
* Revisar labels e textos.
* Corrigir o `ProductSummaryCard`.
* Atualizar o `ProductSummaryCard` quando a marca for alterada.
* Revisar o fluxo completo de autocomplete.

Lista de itens

* Tornar os cards clicáveis para edição.
* Implementar swipe para excluir.
* Melhorar o layout dos cards.
* Exibir marca do produto.
* Exibir quantidade e unidade.
* Exibir preço unitário.
* Exibir preço total do item.



💬 Filosofia do DuoSpend

> **"O app deve pedir pouco e aprender muito."**

começando 22
pausando 23:00
votando 00:30
parando 1:22

## # Sprint 17.7 — Refinamento da UX da Compra
🎯 Objetivo

Refinar a experiência de cadastro de itens na compra, tornando o fluxo mais intuitivo, consistente e preparado para a evolução da inteligência do DuoSpend.

---

✅ Entregas realizadas

Formulário de itens

* Padronização visual dos campos obrigatórios.
* Identificação clara dos campos obrigatórios com `*`.
* Melhor organização dos espaçamentos e hierarquia visual.
* Revisão de labels e textos de apoio.
* Validação visual dos campos obrigatórios.
* Mensagens de erro mais claras para o usuário.

Product Intelligence

* Correção do `ProductSummaryCard`, voltando a exibir corretamente as informações do produto reconhecido.
* Atualização dinâmica do card quando a marca é alterada.
* Manutenção da classificação automática para produtos conhecidos.

Busca inteligente

* Normalização da busca para ignorar diferenças entre letras com e sem acentos.
* Busca funcionando para palavras como:

  * pão / pao
  * açúcar / acucar
  * sabão / sabao
* Revisão do fluxo de autocomplete.

Base de conhecimento

Ampliação da taxonomia de produtos:

* Grãos e cereais.
* Limpeza.
* Hortifrúti.
* Padaria e massas.
* Congelados.
* Temperos e molhos.

Ampliação das unidades disponíveis:

* lata
* garrafa
* pacote
* caixa
* frasco
* sachê
* bandeja
* pote
* rolo
* dúzia

Inclusão de novos produtos na base inicial para facilitar testes e aprendizado.



🧪 Testes realizados

Validação com sucesso dos seguintes cenários:

* reconhecimento de produtos existentes;
* criação de novas marcas;
* atualização do `ProductSummaryCard`;
* categorias automáticas;
* novas unidades;
* autocomplete utilizando nomes normalizados.



## ⚠️ Observação registrada

Durante os testes no emulador foi identificado um comportamento inconsistente na digitação de caracteres compostos (ex.: `ã` e `ç`), em que palavras como "pão" podem aparecer temporariamente como "poo".

Como esse comportamento pode estar relacionado ao teclado do emulador, foi decidido não realizar alterações adicionais neste momento.

A correção foi registrada como a **primeira melhoria prevista para a versão 1.0**, devendo ser validada inicialmente em dispositivo físico.

---

 🏗 Arquitetura

Mantida integralmente:

* Clean Architecture
* SOLID
* Componentização
* Reutilização dos widgets existentes
* Nenhuma quebra estrutural

---

## 📌 Próxima Sprint — 17.8

Refatoração da lista de itens da compra.

Objetivos:

* cards modernos (Material 3);
* tocar no item para editar;
* swipe para excluir;
* animações de inclusão e remoção;
* exibir marca;
* exibir categoria;
* exibir quantidade e unidade;
* exibir preço unitário;
* exibir subtotal;
* layout mais limpo e profissional.

---

💬 Filosofia do DuoSpend

> **"O app deve pedir pouco e aprender muito."**

finalizada em 1h30min

## Sprint 17.8 — UX da Compra (Polimento)

Objetivo
Refinar completamente a experiência de cadastro de itens, tornando o fluxo mais rápido, intuitivo e agradável para uso no mercado.

 Entregas

 1. Preço unitário
- Substituir o campo "Valor total" por "Preço unitário".

 2. Subtotal automático
- Calcular automaticamente:
  quantidade × preço unitário = subtotal.

 3. Preview unificado
- Utilizar exatamente o mesmo PurchaseItemCard da lista durante o cadastro do item.

 4. Atualização em tempo real
- O preview deve reagir instantaneamente conforme o usuário altera:
  - nome
  - marca
  - categoria
  - quantidade
  - unidade
  - preço

 5. Ícones das categorias
- Adicionar ícones Material para cada categoria.

 6. Melhorias visuais
- Espaçamentos
- Hierarquia tipográfica
- Destaque para subtotal
- Melhor organização dos campos

7. Microinterações
- Pequenas animações de transição.
- Feedback visual ao salvar.
- Melhor loading durante busca de produtos.

 Resultado esperado

Cadastrar uma compra deve parecer natural, como colocar produtos no carrinho do mercado.

O usuário informa apenas:
- produto
- quantidade
- preço unitário

O DuoSpend calcula todo o restante automaticamente.

concluido em 1h30



## 📌 Sprint 18 — Shared Wallet (Fundação do modo casal)

📅 Data: 18/07/2026
🕒 Início: ______
🕓 Fim: ______
👤 Participantes: Aline + ChatGPT

🎯 Objetivo

Implementar a infraestrutura do modo compartilhado, permitindo que o DuoSpend suporte múltiplas carteiras (Individual e Compartilhada), preparando toda a arquitetura para uso por duas pessoas.

✅ Escopo
Shared Wallet
criar modelo SharedWallet
criar relacionamento User ↔ Wallet
preparar Wallet para múltiplos usuários
separar carteira Individual e Compartilhada
Home
permitir trocar entre carteiras
atualizar saldo conforme carteira ativa
atualizar listas conforme carteira ativa
Transactions
toda transação pertence à carteira ativa
manter compatibilidade com compras já existentes
Estrutura
remover dependências fixas de uma única wallet
preparar serviços para múltiplas carteiras
deixar arquitetura pronta para Sprint 19
🧪 Testes
criar carteira individual
criar carteira compartilhada
alternar entre elas
adicionar compra em cada carteira
confirmar isolamento dos dados
validar saldo independente
⏱ Estimativa

12 horas

📦 Entrega esperada

✔ DuoSpend funcionando com duas carteiras.

✔ Arquitetura preparada para múltiplos usuários.

✔ Base pronta para divisão de despesas.

levei no máximo 3hrs

## Sprint 18.2 — Wallet Context Global

 Objetivo

Criar um contexto global de carteira ativa para que todo o DuoSpend deixe de assumir automaticamente a carteira `principal` e passe a trabalhar com a carteira atualmente selecionada pelo usuário.

Essa etapa será a base para o funcionamento real do modo compartilhado.

 Escopo

* Criar o `WalletContext` global.
* Armazenar a carteira atualmente selecionada.
* Permitir alternar entre carteira Individual e Compartilhada.
* Preservar a carteira individual antiga como padrão.
* Integrar o contexto ao `AppDependencyContainer`.
* Adaptar o carregamento inicial após o login.
* Preparar Transactions, Shopping, Consumers e Purchases para receber a carteira ativa.
* Evitar IDs de carteira fixos como `principal`.
* Manter compatibilidade com toda a arquitetura existente.
* Executar `flutter analyze` ao final de cada etapa.

 Resultado esperado

Ao final da Sprint 18.2, o aplicativo deverá possuir uma única fonte de verdade para identificar a carteira ativa.

As funcionalidades ainda poderão manter a interface atual, mas a infraestrutura estará preparada para que todas as operações sejam executadas na carteira individual ou compartilhada selecionada.

 Regras técnicas

* Manter Clean Architecture.
* Enviar sempre arquivos completos.
* Nunca enviar apenas trechos.
* Não recriar arquivos sem verificar a implementação existente.
* Preservar tudo que já funciona.
* Fazer alterações incrementais.
* Executar `flutter analyze` após cada arquivo ou etapa relevante.



15min

### Sprint 18.3 — Wallet Switcher

## Objetivo

Permitir que o usuário alterne entre a carteira individual e as carteiras compartilhadas diretamente pela Home, mantendo toda a aplicação sincronizada pelo `WalletContext`.

## Escopo

* Criar componente visual para seleção de carteira.
* Exibir carteira individual e carteiras compartilhadas disponíveis.
* Permitir troca de carteira pela Home.
* Atualizar automaticamente:

  * saldo;
  * receitas;
  * despesas;
  * transações;
  * consumidores;
  * nome da carteira ativa.
* Manter a carteira selecionada centralizada no `WalletContext`.
* Evitar inicializações e recarregamentos manuais duplicados.
* Preparar o fluxo para membros e divisão de despesas na Sprint 19.

## Resultado esperado

O usuário poderá alternar entre:

* carteira individual;
* carteira compartilhada.

Ao selecionar uma carteira, toda a Home e os controllers relacionados deverão refletir automaticamente o novo contexto.

## Estimativa

2 a 3 horas.

## Critérios de aceite

* A carteira ativa pode ser alterada pela interface.
* O nome e o saldo da carteira mudam corretamente.
* As transações exibidas pertencem à carteira selecionada.
* Os consumidores são atualizados automaticamente.
* Não há dados misturados entre carteiras.
* A troca não gera duplicidade de carregamento.
* `flutter analyze` permanece sem novos erros.
