# 10 - Changelog — DuoSpend

## 02/07/2026 — Auditoria do projeto

### Adicionado

- Criação da pasta `Docs` com documentação reorganizada.
- Criação dos documentos solicitados para auditoria e continuidade com IA.

### Identificado

- Projeto Flutter iniciado.
- Firebase configurado.
- Login com Google iniciado.
- Firestore usado para usuários, carteiras e transações.
- Home criada com saldo, resumo, carteira e transações.
- Tela de nova transação criada.

### Problemas encontrados

- `TransactionsPreview` exige `transactions`, mas Home chama sem parâmetro.
- Carteira principal não é criada automaticamente.
- Existem models/repositories duplicados de transação.
- Vários arquivos estão vazios.
- Tema ainda não está centralizado.
- `app/router.dart` vazio.
- `flutter_riverpod` instalado, mas não utilizado.
- Não foi encontrado arquivo de regras Firestore.

### Próximos passos

- Corrigir erro da Home.
- Garantir criação da carteira principal.
- Limpar duplicidades.
- Definir padrão de estado: ChangeNotifier ou Riverpod.
- Aplicar Design System centralizado.
- Definir schema e regras Firestore.
