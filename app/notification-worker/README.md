# DuoSpend Household Reminder Worker

Worker mínimo usado pela Sprint 30 somente para o fluxo **Lembrar responsável**.

## Responsabilidades

- recebe um Firebase ID token do app;
- valida a sessão via Firebase Auth REST API;
- lê a tarefa e o vínculo compartilhado no Firestore usando o token do próprio usuário;
- aplica cooldown autoritativo de 2 horas em D1;
- envia o push pelo OneSignal usando `external_id = Firebase UID`;
- mantém a App API Key do OneSignal apenas no Worker.

Lembretes pessoais agendados não passam por este Worker: eles são notificações locais no dispositivo.

## Configuração

1. Copie `wrangler.toml.example` para `wrangler.toml` e preencha os valores públicos.
2. Localize o banco D1 `duospend-household-reminders` na conta correta e coloque seu `database_id` no arquivo. Crie-o somente se ainda não existir.
3. Aplique `schema.sql` ao banco D1.
4. Grave a chave privada do OneSignal somente como secret:

```bash
npx wrangler secret put ONESIGNAL_REST_API_KEY
```

5. Faça o deploy do Worker e use a URL completa do endpoint no Flutter:

```text
https://<worker>/household/reminders
```

A build Flutter recebe essa URL via:

```bash
--dart-define=HOUSEHOLD_REMINDER_ENDPOINT=https://<worker>/household/reminders
```

O App ID do OneSignal é configurado separadamente no Flutter com:

```bash
--dart-define=ONESIGNAL_APP_ID=<app-id>
```

## Segurança

`ONESIGNAL_REST_API_KEY` nunca deve ser versionada, colocada no Flutter ou enviada por `dart-define`. O Worker deriva o destinatário da própria tarefa persistida; o app não escolhe livremente qualquer `external_id` para envio.

## Auditoria e estado de ativação (22/09/2026)

**IMPLEMENTADO — FALTA DEPLOY** da correção desta pendência.

- O Worker já existia no HEAD base `1722a20`; não foi criada outra arquitetura.
- Logs locais do Wrangler registram deploy em 26/08/2026 na conta Cloudflare
  de Saturnlabs, com o binding D1 `DB` para `duospend-household-reminders`.
- URL encontrada: `https://duospend-household-reminders.saturnlabstech.workers.dev`.
  A consulta GET `/health` retornou HTTP 200 e `{"ok":true}` nesta execução.
- Isso comprova disponibilidade do endpoint de saúde, não envio real, validade
  da chave OneSignal, regras Firestore, versão implantada ou configuração da build.
- Não há `wrangler.toml` local. Há apenas o exemplo versionado. O OAuth local
  do Wrangler possui data de expiração anterior à auditoria; não foi renovado.
- Nenhum deploy, alteração remota, push real ou QA manual foi executado.

## Domínio e contrato

O Firebase configurado em `firebase.json` e `lib/firebase_options.dart` é
`saturnduospend`. Firebase Auth fornece o UID; `users/{uid}` contém perfil
(nome, email, foto e data de criação), não a autoridade de pertencimento à casa.
As tarefas estão em `household_tasks/{taskId}`. Não há documento separado de
household: o escopo é `household:<UIDs únicos ordenados e separados por |>`,
conforme `HouseholdScopeId`. O vínculo atual é conferido em `wallets`, com
`type == shared` e o conjunto exato de `memberIds` correspondente ao escopo.

O endpoint aceita `POST /household/reminders`, `Authorization: Bearer <Firebase
ID token>` e JSON `{"reminderId":"<UUID v4>","taskId":"<id>"}`. Não aceita
UID de remetente/destinatário como autoridade. O serviço Flutter gera o UUID v4;
não existe reminder prévio no Firestore a ser consultado: o Worker registra a
solicitação no D1 após validar a tarefa e a casa.

O Firebase valida a sessão via `accounts:lookup`; o Worker também verifica
projeto, emissor, sujeito e expiração do token. Lê o Firestore com o mesmo token,
portanto as regras publicadas continuam aplicadas. Elas não estão versionadas
neste repositório: antes da ativação, verificar no Firebase Console que clientes
não podem falsificar membros de carteiras ou modificar tarefas de outras casas.
Não é usado service account para contornar essas regras.

Qualquer membro autenticado da mesma casa pode lembrar uma tarefa compartilhada
pendente atribuída a outro membro. O destinatário vem exclusivamente de
`assigneeId`, nunca pode ser o remetente e deve pertencer ao mesmo vínculo.

| HTTP | Significado |
| --- | --- |
| 200 | `ok: true` e `messageId` não vazio: OneSignal aceitou a notificação |
| 200 + `idempotent: true` | A mesma solicitação já foi aceita, sem novo envio |
| 400 | JSON/IDs inválidos; `reminderId` deve ser UUID v4 |
| 401 | Sessão ausente, inválida, desabilitada ou expirada |
| 403 | Sem autorização ou sem vínculo correspondente no Firestore |
| 404 | Tarefa inexistente ou rota inexistente |
| 409 | Tarefa/contexto incompatível, reutilização de ID ou retry expirado |
| 422 | OneSignal informou indisponibilidade de destinatário inscrito |
| 429 | Cooldown de duas horas; inclui `retryAfterSeconds` |
| 502/503 | Falha do provedor/dependência, rede ou configuração ausente |
| 500 | Falha interna, sem expor detalhes de credenciais ou respostas externas |

Erros contêm `error`; falhas de entrega podem incluir `code`. O Flutter preserva
o HTTP em `HouseholdReminderDeliveryException` e só conclui com sucesso quando
`ok == true` e `messageId` é uma string não vazia. HTTP 200 isolado, JSON inválido
ou corpo incompleto são erros. Aceitação pelo OneSignal não confirma recebimento
físico pelo dispositivo; não há recibo de entrega neste fluxo.

## OneSignal e idempotência

O SDK instalado é `onesignal_flutter 5.6.10`, com `OneSignal.login(user.uid)` e
logout já integrados. O servidor usa `POST https://api.onesignal.com/notifications`,
`Authorization: Key <secret>`, `include_aliases.external_id: [assigneeId]` e
`target_channel: push`. Não usa broadcast, segmentos ou subscription ID do cliente.
O texto é genérico, sem título/notas da tarefa na tela bloqueada; preserva o
payload existente `type`, `taskId`, `scopeId`, `kind`, sem introduzir navegação.

O D1 reserva o `reminderId` antes da chamada externa, com associação imutável
à tarefa, casa, remetente e destinatário. Replays validam novamente a autorização.
O cooldown é adquirido atomicamente por tarefa/remetente/destinatário, inclusive
em concorrência. A chamada OneSignal usa o mesmo UUID como `idempotency_key`:
retries após timeout ou falha de gravação D1 reutilizam a chave. O payload é
estável mesmo se o título da tarefa mudar. Solicitações ambíguas com 29 dias ou
mais são recusadas antes do fim da retenção de 30 dias do provedor.

Não apagar registros D1 de solicitações para tentar reenviar. Se o processo
encerrar abruptamente depois de adquirir o cooldown, o retry pode aguardar até
duas horas. Após falha tratada o cooldown é liberado; a reserva do ID permanece.
Uma nova ação manual gera outro UUID; não é tratada como retry do mesmo lembrete.
O schema existente é reutilizado sem migração destrutiva.

Referências oficiais: [envio por aliases e resposta](https://documentation.onesignal.com/reference/create-message),
[idempotência](https://documentation.onesignal.com/reference/idempotent-notification-requests),
[Firebase Auth REST](https://firebase.google.com/docs/reference/rest/auth).

## Procedimento exato para publicar a correção

Os comandos abaixo são instruções para ativação; não foram executados nesta tarefa.
Requerem Node.js e acesso autorizado à conta Cloudflare usada pelo deploy anterior.
Execute a partir de `app/notification-worker`:

```powershell
npx wrangler login
npx wrangler whoami
npx wrangler d1 list
Copy-Item wrangler.toml.example wrangler.toml
```

No `wrangler.toml` local (ignorado pelo Git), configurar:

- `account_id`: a conta do Worker existente, confirmada em `whoami`/Console.
- `FIREBASE_PROJECT_ID`: `saturnduospend`.
- `FIREBASE_WEB_API_KEY`: chave pública desse projeto, obtida em
  Firebase Console > Configurações do projeto ou em `lib/firebase_options.dart`.
- `ONESIGNAL_APP_ID`: o mesmo App ID da build Flutter, obtido em OneSignal >
  Settings > Keys & IDs (há um valor público padrão no `PushNotificationService`).
- Binding `DB`, `database_name = duospend-household-reminders` e `database_id`
  retornado por `d1 list`. Reutilizar o banco do Worker existente.

Se o banco realmente não existir, criar antes com
`npx wrangler d1 create duospend-household-reminders` e usar o ID retornado.
Aplicar o schema não destrutivo, conferir o nome do secret existente e publicar:

```powershell
npx wrangler d1 execute duospend-household-reminders --remote --file=schema.sql
npx wrangler secret list
# Apenas se o secret estiver ausente ou precisar ser atualizado:
npx wrangler secret put ONESIGNAL_REST_API_KEY
npx wrangler deploy
```

O secret é a App API Key privilegiada do mesmo aplicativo OneSignal. Inserir
somente no prompt seguro do Wrangler ou no painel Cloudflare > Worker > Settings >
Variables and Secrets. Não passá-lo na linha de comando, em arquivo versionado,
asset, `.env` versionado ou `dart-define`. O `secret list` mostra nomes, não valores.

Usar a URL exibida pelo deploy com `/household/reminders`; se a conta/nome forem
mantidos, a URL histórica é:
`https://duospend-household-reminders.saturnlabstech.workers.dev/household/reminders`.
Gerar a build a partir de `app` com os valores públicos:

```powershell
flutter build apk --dart-define=HOUSEHOLD_REMINDER_ENDPOINT=https://duospend-household-reminders.saturnlabstech.workers.dev/household/reminders --dart-define=ONESIGNAL_APP_ID=<APP_ID_PUBLICO>
```

Para iOS, passar os mesmos defines ao processo habitual de build em macOS.
Confirmar no OneSignal a configuração push Android/iOS e a inscrição dos
dispositivos; `/health` sozinho não valida essas integrações.

## Validação futura com dois usuários/dispositivos

Após configuração/deploy, entrar com A e B em dois dispositivos com push permitido.
Confirmar que cada inscrição OneSignal usa seu próprio Firebase UID e que ambos
pertencem à mesma carteira compartilhada. A cria/seleciona tarefa pendente atribuída
a B e usa “Lembrar responsável”: somente B deve receber o push. Confirmar sucesso
no app e o `messageId`/destinatário no painel OneSignal. Repetir a mesma requisição
com o mesmo `reminderId`: deve retornar sucesso idempotente sem outro push; uma
nova ação antes de duas horas deve bloquear por cooldown. Testar sessão ausente,
usuário de outra casa e B sem assinatura push, sem falso sucesso. Esta validação
manual não foi executada nesta tarefa.

## Testes locais

Resultado desta execução: **27 testes backend e 25 testes Flutter focados
passaram**, incluindo os 26 casos backend anteriores. A análise estática dos
três arquivos Dart desta pendência não encontrou problemas.

Backend usa Node.js 24 e SQLite real em memória para exercitar o SQL D1, com
Firebase/Firestore/OneSignal simulados; nenhuma chamada externa nos testes:

```powershell
npm run check
npm test
```

Em `app`, executar somente os testes focados:

```powershell
flutter test --no-pub test/hybrid_household_task_reminder_repository_test.dart test/household_task_reminder_service_test.dart
```
