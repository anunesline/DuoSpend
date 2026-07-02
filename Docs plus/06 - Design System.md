# 06 - Design System — DuoSpend

## Personalidade visual

O DuoSpend deve transmitir calma, organização e confiança.

## Cores atuais encontradas

Arquivo: `app/lib/core/theme/app_colors.dart`

```dart
primary: Color(0xFF2563EB)
secondary: Color(0xFF7C3AED)
background: Color(0xFFF8FAFC)
surface: Colors.white
textPrimary: Color(0xFF0F172A)
textSecondary: Color(0xFF64748B)
success: Color(0xFF22C55E)
warning: Color(0xFFF59E0B)
error: Color(0xFFEF4444)
border: Color(0xFFE2E8F0)
```

## Cores usadas diretamente em widgets

- `Color(0xFF4F46E5)`
- `Color(0xFF6366F1)`
- `Color(0xFFF8F9FC)`
- `Colors.green`
- `Colors.red`
- `Colors.grey`

## Problema atual

O Design System existe como intenção, mas ainda não está centralizado. A Home e os cards usam cores diretas em vez de consumir `AppColors` e `AppTheme`.

## Recomendação

Centralizar em:

```text
core/theme/
├── app_colors.dart
├── app_text_styles.dart
└── app_theme.dart
```

## Componentes atuais

- `BalanceCard`
- `SummaryCard`
- `WalletCard`
- `TransactionsPreview`

## Componentes sugeridos

- `AppScaffold`
- `AppCard`
- `MoneyText`
- `EmptyState`
- `LoadingState`
- `ErrorState`
- `PrimaryButton`
- `AppTextField`

## Padrão de dinheiro

Hoje os valores são exibidos com `toStringAsFixed(2)`. Futuramente, criar helper de formatação BRL para exibir `R$ 1.250,90`.

## Direção visual

- Azul: área principal/individual.
- Roxo: área compartilhada/casal.
- Verde: receitas/sucesso.
- Vermelho: despesas/erro.
- Laranja: alertas.
