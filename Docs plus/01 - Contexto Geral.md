# 01 - Contexto Geral — DuoSpend

Data da auditoria: 02/07/2026

## O que é o DuoSpend

O DuoSpend é um aplicativo Flutter de controle financeiro pessoal e compartilhado, pensado para uso individual e também para casais. A ideia central é permitir que cada pessoa tenha seu próprio login e consiga controlar seus dados financeiros pessoais, enquanto um espaço compartilhado pode reunir gastos, receitas, metas e visão do casal.

## Decisão principal do produto

Não existe “login do casal”. Existem contas individuais que podem ser vinculadas a um espaço compartilhado.

```text
Aline  ─┐
        ├── Espaço compartilhado do casal
João   ─┘
```

## Estrutura recebida na auditoria

```text
DuoSpend/
├── app/      # Aplicativo Flutter
├── docs/     # Documentação anterior do projeto
```

A documentação anterior cita também as pastas `assets/`, `backend` e `design`, mas nesta extração o conteúdo útil auditado ficou principalmente em `app/` e `docs/`.

## Estado geral encontrado

- Flutter criado com estrutura padrão multiplataforma.
- Firebase configurado no app.
- Login com Google iniciado.
- Firestore sendo usado para usuários, carteiras e transações.
- Home inicial criada.
- Tela de nova transação criada.
- Design visual inicial aplicado manualmente.
- Documentação antiga existe, mas incompleta e com arquivos vazios.

## Observação da auditoria

O pacote enviado estava em `.rar`. A leitura da estrutura e dos arquivos principais foi concluída, mas a validação com `flutter analyze` não pôde ser executada neste ambiente porque o comando `flutter` não está disponível no sandbox.
