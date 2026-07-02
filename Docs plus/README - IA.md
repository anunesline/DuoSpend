# README - IA — DuoSpend

Este arquivo serve como guia para qualquer IA ou pessoa que continue o desenvolvimento do DuoSpend.

## Contexto rápido

DuoSpend é um app Flutter de controle financeiro individual e compartilhado para casais.

A regra central é: cada pessoa tem seu próprio login. O casal não tem um login único; os usuários individuais serão vinculados a um espaço compartilhado.

## Estado atual real

O projeto já tem Flutter, Firebase, login com Google, criação de usuário no Firestore, Home inicial, carteira principal como conceito, cadastro de transação, atualização de saldo e widget de prévia de transações.

Mas ainda precisa de correções antes de avançar.

## Antes de criar coisa nova, corrigir

1. Corrigir chamada de `TransactionsPreview` em `HomePage`:

```dart
TransactionsPreview(
  transactions: controller.transactions,
),
```

2. Criar carteira principal automaticamente se não existir.

3. Decidir onde ficará o modelo oficial de transação.

Recomendação:

```text
features/transactions/data/models/transaction_model.dart
```

4. Remover ou preencher arquivos vazios.
5. Aplicar o Design System centralizado.

## Arquitetura desejada

Usar Feature First:

```text
features/
└── feature_name/
    ├── data/
    ├── domain/
    └── presentation/
```

## Backend

Usar Firebase no MVP:

- Firebase Auth
- Google Sign-In
- Cloud Firestore

Estrutura atual/futura:

```text
users/{uid}
users/{uid}/wallets/principal
users/{uid}/transactions/{transactionId}
shared_spaces/{spaceId}
shared_spaces/{spaceId}/members/{uid}
shared_spaces/{spaceId}/transactions/{transactionId}
```

## Não perder essas decisões

- Produto deve ser simples e leve.
- Usuário individual primeiro.
- Área compartilhada depois.
- Lista de compras será funcionalidade futura.
- Modos de tom/humor são diferenciais futuros.
- Documentação deve ser viva e atualizada por sprint.

## Próxima tarefa recomendada

Executar a Sprint de correção do MVP individual:

1. Corrigir Home.
2. Criar carteira principal automática.
3. Garantir que login → home → nova transação → saldo → histórico funcione.
4. Só depois avançar para casal, metas e lista de compras.
