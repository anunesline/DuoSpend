# 03 - PRD — DuoSpend

## Produto

DuoSpend — aplicativo de controle financeiro individual e compartilhado.

## Problema

Pessoas e casais têm dificuldade para acompanhar gastos, dividir responsabilidades financeiras e entender para onde o dinheiro está indo. Muitas ferramentas são complexas, frias ou exigem esforço demais.

## Solução

Um app mobile simples com login individual, carteira principal, transações e visão evolutiva para casal, metas e relatórios.

## MVP pretendido

1. Login com Google.
2. Criação/registro do usuário no Firestore.
3. Criação ou leitura da carteira principal.
4. Cadastro de receitas e despesas.
5. Atualização automática do saldo.
6. Exibição de saldo total.
7. Exibição de total de receitas e despesas.
8. Prévia das últimas movimentações.

## Estado atual encontrado

### Já existe

- App Flutter criado.
- Firebase inicializado.
- Login com Google em `AuthService`.
- Criação de usuário em `users/{uid}`.
- Modelos de usuário, carteira e transação.
- Repositórios para usuário, carteira e transações.
- Home com saldo, resumo e carteira.
- Tela de nova transação.
- Atualização de saldo ao salvar transação.

### Parcial

- Histórico de transações existe no controller e no widget, mas a Home não está passando a lista para o widget.
- Carteira principal aparece na Home, mas depende de documento já existir no Firestore.
- Design system existe como intenção e arquivo de cores, mas ainda não foi aplicado como tema central.

### Não existe ainda

- Cadastro por e-mail/senha.
- Splash funcional.
- Roteamento oficial.
- Onboarding.
- Área compartilhada do casal.
- Convite/vínculo entre usuários.
- Regras de permissão no Firestore documentadas no projeto.
- Tela de detalhe da carteira.
- Edição/exclusão de transações.
- Categorias.
- Metas.
- Relatórios.
- Lista de compras.
- Testes relevantes.

## Requisitos funcionais do MVP

- RF01 — Usuário deve conseguir entrar com Google.
- RF02 — Após login, o app deve salvar dados básicos do usuário no Firestore.
- RF03 — Todo usuário deve ter uma carteira principal criada automaticamente.
- RF04 — Usuário deve cadastrar descrição, valor e tipo: receita ou despesa.
- RF05 — Ao salvar receita, saldo aumenta; ao salvar despesa, saldo diminui.
- RF06 — Home deve exibir saldo, receitas, despesas, carteira principal e últimas movimentações.

## Critérios de aceite

- App abre sem erro.
- Login Google funciona no Android.
- Usuário é salvo no Firestore.
- Carteira principal é criada automaticamente no primeiro acesso.
- Nova transação salva no Firestore.
- Saldo é atualizado corretamente.
- Home mostra últimas movimentações sem erro.
