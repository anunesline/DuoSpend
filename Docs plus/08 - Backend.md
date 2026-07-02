# 08 - Backend — DuoSpend

## Backend atual

O backend atual é Firebase.

Dependências encontradas no `pubspec.yaml`:

```yaml
firebase_core: ^3.0.0
firebase_auth: ^5.7.0
cloud_firestore: ^5.0.0
google_sign_in: ^6.2.1
```

## Firebase configurado

Arquivo encontrado: `app/lib/firebase_options.dart`

Projeto Firebase identificado: `saturn-duospend`

## Serviços usados

- Firebase Authentication
- Google Sign-In
- Cloud Firestore

## Estrutura Firestore atual

```text
users/{uid}
users/{uid}/wallets/principal
users/{uid}/transactions/{transactionId}
```

## Fluxo de login atual

1. Usuário clica em “Entrar com Google”.
2. App abre Google Sign-In.
3. Credencial é enviada ao Firebase Auth.
4. Usuário autenticado é salvo no Firestore.
5. App navega para Home.

## Problemas encontrados

### 1. Carteira principal não é criada no login

O código busca `users/{uid}/wallets/principal`, mas não foi encontrado método garantindo a criação inicial dessa carteira.

### 2. Uso de `.update()` em carteira

`updateBalance()` usa `.update()`. Se o documento `principal` não existir, a operação falha.

Recomendação: usar `.set(..., SetOptions(merge: true))` ou criar a carteira no onboarding/login.

### 3. Segurança Firestore não documentada

Não há arquivo de regras encontrado nesta auditoria.

Sugestão mínima conceitual:

```text
users/{userId}: somente o próprio usuário pode ler/escrever.
users/{userId}/transactions/{transactionId}: somente o próprio usuário pode ler/escrever.
users/{userId}/wallets/{walletId}: somente o próprio usuário pode ler/escrever.
```

### 4. Chaves Firebase no repositório

`firebase_options.dart` e `google-services.json` estão no projeto. Isso é comum em apps Firebase, mas antes de publicação é necessário revisar regras, restrições de API key e configuração por ambiente.

## Próximos passos de backend

1. Criar método `ensureMainWallet()`.
2. Chamar `ensureMainWallet()` depois do login.
3. Definir regras Firestore.
4. Padronizar schema de dados.
5. Preparar estrutura futura para espaço compartilhado.
6. Criar tratamento de erros nos repositories.
