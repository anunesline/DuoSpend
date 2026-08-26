# Rotinas da Casa — notificações push

A Sprint 30 usa Firebase Cloud Messaging (FCM) com Cloud Functions e Cloud Tasks.

## Fluxo

1. O app solicita permissão de notificação e obtém o token FCM do dispositivo.
2. O token é registrado por uma Callable Function autenticada em `users/{uid}/fcm_tokens`.
3. `createHouseholdReminder` valida o usuário, a tarefa, o responsável e o vínculo compartilhado.
4. Lembretes ao parceiro passam por cooldown autoritativo de 2 horas.
5. O backend grava o lembrete e cria uma Cloud Task para `dispatchHouseholdReminder` no horário solicitado.
6. A task envia a notificação via FCM e marca o lembrete como `delivered` ou `failed`.
7. Em foreground, o Flutter mostra a mensagem via `ScaffoldMessenger`; em background/encerrado, o sistema operacional apresenta o push do FCM.

Nenhuma credencial de servidor FCM fica no aplicativo Flutter.

## Deploy do backend

O projeto Firebase é `saturn-duospend`.

A partir de `app/`:

```bash
cd functions
npm install
npm run lint
cd ..
npx firebase-tools deploy --project saturn-duospend --only functions
```

Task Queue Functions usam Cloud Tasks e exigem projeto no plano Blaze. No primeiro deploy, o Firebase cria/configura a fila associada à função. Se o deploy solicitar APIs ou permissões adicionais, habilite Cloud Tasks e as permissões de enfileiramento/invocação indicadas pelo Firebase CLI.

## Android

`POST_NOTIFICATIONS` está declarado no `AndroidManifest.xml`. Em Android 13+, o app solicitará a permissão em runtime através do Firebase Messaging.

Teste em aparelho físico ou emulador com Google Play Services.

## iOS

Além do código Flutter, FCM em iOS exige configuração na conta Apple/Firebase:

- habilitar **Push Notifications** em Signing & Capabilities no target Runner;
- habilitar **Background Modes**, incluindo Remote notifications (e Background fetch quando aplicável);
- criar/obter a chave APNs no Apple Developer;
- enviar a chave APNs na configuração Cloud Messaging do projeto Firebase.

Essa etapa requer macOS/Xcode e credenciais da conta Apple Developer; não há chave APNs versionada no repositório.

## Validação funcional

- lembrete pessoal agendado para alguns minutos à frente deve chegar com o app em background;
- `Lembrar responsável` deve chegar imediatamente ao outro usuário;
- nova tentativa de lembrar o mesmo responsável antes de 2 horas deve ser bloqueada;
- com o app em foreground, a mensagem deve aparecer dentro do DuoSpend;
- token inválido deve ser removido pelo backend após resposta do FCM;
- o documento do lembrete deve terminar como `delivered` em sucesso ou `failed` em falha.
