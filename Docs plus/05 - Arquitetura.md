# 05 - Arquitetura — DuoSpend

## Stack atual

- Flutter
- Dart
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Google Sign-In
- Riverpod instalado, mas ainda não utilizado de forma efetiva

## Estrutura atual encontrada

```text
app/lib/
├── app/
│   ├── app.dart
│   ├── router.dart              # vazio
│   └── theme.dart               # vazio
├── core/
│   ├── services/auth/auth_service.dart
│   └── theme/
│       ├── app_colors.dart
│       ├── app_text_styles.dart # vazio
│       └── app_theme.dart       # vazio
├── features/
│   ├── auth/
│   ├── expenses/                # arquivos vazios
│   ├── home/
│   └── transactions/
├── firebase_options.dart
└── main.dart
```

## Arquitetura pretendida

A documentação anterior definiu arquitetura Feature First.

```text
features/
└── nome_da_feature/
    ├── data/
    │   ├── models/
    │   └── repositories/
    ├── domain/
    │   └── entities/
    └── presentation/
        ├── controllers/
        ├── pages/
        └── widgets/
```

## Backend atual

Firebase, sem servidor próprio.

Coleções usadas ou esperadas:

```text
users/{uid}
users/{uid}/wallets/principal
users/{uid}/transactions/{transactionId}
```

## Pontos positivos

- Boa escolha inicial para MVP: Firebase reduz complexidade.
- Separação por features já começou.
- Models e repositories já existem.
- App já possui autenticação e persistência inicial.

## Problemas arquiteturais encontrados

1. Existem `app/lib/main.dart` e `app/lib/app.dart` com função `main()`. O Flutter normalmente usa `lib/main.dart`.
2. Existem models de transação em `features/home` e `features/transactions`.
3. Também há repository de transação duplicado.
4. Há vários arquivos vazios em `auth`, `expenses`, `core/theme`, `app/router.dart` e `app/theme.dart`.
5. `flutter_riverpod` está instalado, mas o app usa `ChangeNotifier` manualmente.
6. Não foi encontrado arquivo de regras Firestore.

## Recomendação imediata

Para ir rápido, manter Firebase + Firestore + ChangeNotifier temporariamente e corrigir:

1. Home compilando.
2. Carteira principal criada automaticamente.
3. Duplicidade de transações removida.
4. Tema central aplicado.
5. Firestore rules definidas.
