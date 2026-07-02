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
terminando: 23:58