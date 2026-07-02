# 07 - Regras de Negócio — DuoSpend

## Usuário

- Cada usuário possui seu próprio login.
- Cada usuário possui seus próprios dados financeiros individuais.
- O usuário é salvo em `users/{uid}` após login.

## Carteira

- Todo usuário deve ter uma carteira principal.
- A carteira principal deve usar o ID `principal`.
- A carteira principal deve ser criada automaticamente se não existir.
- O saldo da carteira deve refletir receitas menos despesas.

## Transações

Toda transação pertence a um usuário autenticado e deve ter ID, descrição, valor, tipo e data.

Tipos válidos:

- `income` para receita.
- `expense` para despesa.

## Atualização de saldo

- Ao salvar `income`, somar valor ao saldo.
- Ao salvar `expense`, subtrair valor do saldo.

## Regras que ainda precisam ser definidas

- O saldo pode ficar negativo?
- Transação pode ser editada?
- Ao editar transação, como recalcular saldo?
- Ao excluir transação, como reverter saldo?
- Haverá categorias obrigatórias?
- Haverá data manual da transação ou sempre data atual?
- Haverá múltiplas carteiras?
- Gastos compartilhados serão divididos igualmente ou por percentual?

## Área compartilhada

- Dois usuários individuais podem estar vinculados a um espaço compartilhado.
- Dados pessoais continuam privados.
- Dados compartilhados pertencem ao espaço do casal.

Estrutura futura sugerida:

```text
shared_spaces/{spaceId}
shared_spaces/{spaceId}/members/{uid}
shared_spaces/{spaceId}/transactions/{transactionId}
shared_spaces/{spaceId}/shopping_lists/{listId}
```

## Lista de compras

- Lista pode ser individual ou compartilhada.
- Item deve ter nome, quantidade, status e opcionalmente valor.
- Compra finalizada pode gerar histórico.
- Futuramente, item comprado pode alimentar análise de duração.
