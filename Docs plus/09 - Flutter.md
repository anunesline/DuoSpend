# 09 - Flutter — DuoSpend

## Estado atual do app Flutter

O app Flutter já foi criado e possui estrutura padrão para Android, iOS, Web, Windows, Linux e macOS.

## Dependências principais

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `google_sign_in`
- `flutter_riverpod`

## Telas encontradas

### LoginPage

Arquivo: `features/auth/presentation/pages/login_page.dart`

Status: funcional em conceito.

Função:

- Mostra marca DuoSpend.
- Mostra texto de posicionamento.
- Botão “Entrar com Google”.
- Após login, navega para Home.

### HomePage

Arquivo: `features/home/presentation/pages/home_page.dart`

Status: parcialmente funcional.

Mostra saldo, receitas, despesas, carteira principal e últimas movimentações.

Problema encontrado:

```dart
TransactionsPreview(),
```

Mas o widget exige:

```dart
TransactionsPreview({required this.transactions})
```

Correção sugerida:

```dart
TransactionsPreview(
  transactions: controller.transactions,
),
```

### NewTransactionPage

Arquivo: `features/transactions/presentation/pages/new_transaction_page.dart`

Permite descrição, valor, tipo receita/despesa e salvar transação.

## Controllers

### HomeController

Carrega carteira principal, transações, total de receitas e total de despesas.

### TransactionController

Salva transação e atualiza saldo da carteira.

## Problemas Flutter encontrados

1. `TransactionsPreview` está sendo chamado sem o parâmetro obrigatório.
2. Home mostra “Olá, Aline” fixo; deve buscar nome do usuário autenticado.
3. Há vários arquivos vazios.
4. `AppColors` existe, mas os widgets usam cores diretas.
5. `app/router.dart` está vazio.
6. `flutter_riverpod` está instalado e não usado.

## Correções imediatas recomendadas

1. Corrigir `TransactionsPreview` na Home.
2. Criar carteira principal automaticamente.
3. Remover duplicidade de `TransactionModel`.
4. Padronizar tema.
5. Criar tela de histórico/listagem.
6. Criar loading na Home usando `controller.isLoading`.
7. Trocar saudação fixa pelo usuário logado.
