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
2. Crie um banco D1 chamado `duospend-household-reminders` e coloque o `database_id` no arquivo.
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
