# 🏗️ DuoSpend - Arquitetura

## Visão Geral

O DuoSpend é um aplicativo de controle financeiro com duas áreas distintas:

- 👤 Área Individual
- ❤️ Área Compartilhada (Casal)

Cada usuário possui sua própria conta e seus próprios dados.

O espaço compartilhado pertence ao casal e pode ser acessado pelos dois usuários vinculados.

---

# Estrutura do Projeto

lib/

app/
Configuração do aplicativo.

core/
Serviços e recursos utilizados por todo o sistema.

shared/
Componentes reutilizáveis.

features/
Todas as funcionalidades do aplicativo.

---

# Features

- Auth
- Onboarding
- Dashboard
- Individual
- Couple
- Transactions
- Goals
- Reports
- Profile
- Settings

---

# Padrões

Arquitetura Feature First.

Cada feature possui:

- data
- domain
- presentation

---

# Backend

Firebase

- Authentication
- Firestore
- Storage (futuro)
- Cloud Functions (futuro)

---

# Objetivo

Criar um aplicativo escalável, organizado e preparado para evolução contínua.