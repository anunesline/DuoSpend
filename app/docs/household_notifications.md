# Rotinas da Casa — notificações

A Sprint 30 separa dois tipos de lembrete sem depender de Cloud Functions/Cloud Tasks:

- **Lembrete pessoal**: notificação local agendada no próprio dispositivo com `flutter_local_notifications`.
- **Lembrar responsável**: push remoto pelo OneSignal, enviado através de um Cloudflare Worker seguro.

## Identidade de push

O Flutter inicializa o OneSignal com `ONESIGNAL_APP_ID` e usa o Firebase UID como `external_id` através de `OneSignal.login(uid)`. Ao sair da conta, o SDK executa `OneSignal.logout()`.

A App API Key do OneSignal nunca fica no aplicativo.

## Lembrete pessoal

Quando o usuário agenda um lembrete para si:

1. o domínio valida que a tarefa está pendente e que o horário não está no passado;
2. o app busca o título da tarefa;
3. agenda uma notificação local no fuso horário do dispositivo;
4. no Android, o app solicita permissão de notificações e de alarme exato quando necessário;
5. o lembrete continua independente de backend e de plano Blaze.

## Lembrar responsável

Quando uma tarefa compartilhada está atribuída a outro membro:

1. o app obtém um Firebase ID token da sessão atual;
2. envia somente `reminderId` e `taskId` ao Worker;
3. o Worker valida a sessão no Firebase Auth;
4. lê a tarefa e valida o escopo compartilhado no Firestore usando o token do próprio usuário;
5. confirma que remetente e responsável fazem parte de uma carteira compartilhada conectada;
6. aplica cooldown autoritativo de 2 horas em D1;
7. envia o push pelo OneSignal para `external_id = Firebase UID` do responsável;
8. registra o envio no D1.

O destinatário não é aceito livremente do cliente: ele é derivado da tarefa persistida.

## Configuração da build Flutter

A build precisa dos dois valores abaixo:

```bash
--dart-define=ONESIGNAL_APP_ID=<onesignal-app-id>
--dart-define=HOUSEHOLD_REMINDER_ENDPOINT=https://<worker>/household/reminders
```

`ONESIGNAL_APP_ID` não é uma credencial secreta. Já a App API Key do OneSignal é secreta e existe somente no Worker.

## Worker

A implementação está em `notification-worker/`.

Variáveis públicas/configuráveis do Worker:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_WEB_API_KEY`
- `ONESIGNAL_APP_ID`

Secret obrigatório:

- `ONESIGNAL_REST_API_KEY`

Binding obrigatório:

- `DB` apontando para o banco D1 criado com `notification-worker/schema.sql`

## Cloud Functions / FCM

A implementação intermediária baseada em `firebase_messaging`, Cloud Functions e Cloud Tasks foi removida do closeout. O Flutter da Sprint 30 não registra tokens FCM diretamente e não depende de deploy no plano Blaze.

O Firebase continua sendo usado normalmente para autenticação e dados do DuoSpend.

## Validação funcional

- lembrete pessoal deve disparar no horário escolhido mesmo sem backend;
- `Lembrar responsável` deve chegar ao outro usuário pelo OneSignal;
- nova tentativa para a mesma tarefa/remetente/responsável antes de 2 horas deve retornar cooldown;
- usuário não conectado ao mesmo contexto compartilhado não pode disparar push;
- build sem `ONESIGNAL_APP_ID` deve continuar abrindo normalmente, apenas com push remoto desabilitado;
- build sem `HOUSEHOLD_REMINDER_ENDPOINT` deve permitir tarefas e lembretes locais, mas bloquear envio ao responsável com erro controlado.
