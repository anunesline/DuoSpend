const PARTNER_COOLDOWN_MS = 2 * 60 * 60 * 1000;

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

function requireString(value, field) {
  const normalized = typeof value === "string" ? value.trim() : "";
  if (!normalized || normalized.length > 128 || /[\/\x00-\x1f]/.test(normalized)) {
    throw new HttpError(400, `${field} is required.`);
  }
  return normalized;
}

class HttpError extends Error {
  constructor(status, message, details = {}) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

function bearerToken(request) {
  const header = request.headers.get("authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) throw new HttpError(401, "Authentication is required.");
  return match[1].trim();
}

async function upstreamFetch(url, options) {
  try {
    return await fetch(url, {...options, signal: AbortSignal.timeout(15000)});
  } catch (_) {
    throw new HttpError(503, "Serviço temporariamente indisponível.", {code: "temporary_delivery_error"});
  }
}

async function firebaseUserId(idToken, env) {
  const response = await upstreamFetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${encodeURIComponent(env.FIREBASE_WEB_API_KEY)}`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({idToken}),
    },
  );

  if (response.status >= 500 || response.status === 429) throw new HttpError(503, "Firebase Auth unavailable.");
  if (!response.ok) {
    throw new HttpError(401, "Invalid Firebase session.");
  }

  const data = await response.json();
  const uid = data && data.users && data.users[0] && data.users[0].localId;
  if (!uid || data.users[0].disabled) throw new HttpError(401, "Invalid Firebase session.");
  // Signature/session validation above is authoritative. Also bind to this project
  // and reject expired tokens even if the account lookup still accepts them.
  let claims;
  try { claims = JSON.parse(atob(idToken.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))); }
  catch (_) { throw new HttpError(401, "Invalid Firebase token."); }
  if (!claims || claims.aud !== env.FIREBASE_PROJECT_ID ||
      claims.iss !== `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}` ||
      claims.sub !== uid || !Number.isFinite(claims.exp) || claims.exp <= Date.now() / 1000) {
    throw new HttpError(401, "Invalid or expired Firebase token.");
  }
  return String(uid);
}

function firestoreBase(env) {
  return `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(env.FIREBASE_PROJECT_ID)}/databases/(default)`;
}

async function firestoreFetch(url, idToken, options = {}) {
  const response = await upstreamFetch(url, {
    ...options,
    headers: {
      ...(options.headers || {}),
      authorization: `Bearer ${idToken}`,
      "content-type": "application/json",
    },
  });

  if (response.status === 404) return null;
  if (!response.ok) {
    throw new HttpError(
      response.status === 403 ? 403 : 502,
      response.status === 403
        ? "Firestore denied access to this household context."
        : "Firestore temporarily unavailable.",
    );
  }
  return response.json();
}

function stringField(fields, name) {
  return fields && fields[name] && fields[name].stringValue
    ? String(fields[name].stringValue)
    : "";
}

function stringArrayField(fields, name) {
  const values =
    fields &&
    fields[name] &&
    fields[name].arrayValue &&
    Array.isArray(fields[name].arrayValue.values)
      ? fields[name].arrayValue.values
      : [];
  return values
    .map((item) => item && item.stringValue)
    .filter(Boolean)
    .map(String);
}

function sharedMembers(scopeId) {
  if (!scopeId.startsWith("household:")) return [];
  return scopeId
    .substring("household:".length)
    .split("|")
    .map((value) => value.trim())
    .filter(Boolean);
}

async function loadTask(taskId, idToken, env) {
  const encodedTaskId = encodeURIComponent(taskId);
  const document = await firestoreFetch(
    `${firestoreBase(env)}/documents/household_tasks/${encodedTaskId}`,
    idToken,
  );
  if (!document) throw new HttpError(404, "Household task not found.");
  return document.fields || {};
}

async function validateConnectedHousehold(senderUserId, recipientUserId, scopeId, idToken, env) {
  const body = {
    structuredQuery: {
      from: [{collectionId: "wallets"}],
      where: {
        fieldFilter: {
          field: {fieldPath: "memberIds"},
          op: "ARRAY_CONTAINS",
          value: {stringValue: senderUserId},
        },
      },
    },
  };

  const rows = await firestoreFetch(
    `${firestoreBase(env)}/documents:runQuery`,
    idToken,
    {method: "POST", body: JSON.stringify(body)},
  );

  const connected = Array.isArray(rows) && rows.some((row) => {
    const fields = row && row.document && row.document.fields;
    if (!fields || stringField(fields, "type") !== "shared") return false;
    const members = stringArrayField(fields, "memberIds");
    return members.includes(senderUserId) && members.includes(recipientUserId) &&
      `household:${[...new Set(members)].sort().join("|")}` === scopeId;
  });

  if (!connected) {
    throw new HttpError(
      403,
      "The users are not connected in a shared household.",
    );
  }
}

async function acquireCooldown(env, key, taskId, senderUserId, recipientUserId, nowMs) {
  const cutoffMs = nowMs - PARTNER_COOLDOWN_MS;
  const row = await env.DB.prepare(`
    INSERT INTO partner_reminder_cooldowns (
      cooldown_key,
      task_id,
      sender_user_id,
      recipient_user_id,
      last_sent_at_ms
    ) VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(cooldown_key) DO UPDATE SET
      task_id = excluded.task_id,
      sender_user_id = excluded.sender_user_id,
      recipient_user_id = excluded.recipient_user_id,
      last_sent_at_ms = excluded.last_sent_at_ms
    WHERE partner_reminder_cooldowns.last_sent_at_ms <= ?
    RETURNING last_sent_at_ms
  `)
    .bind(
      key,
      taskId,
      senderUserId,
      recipientUserId,
      nowMs,
      cutoffMs,
    )
    .first();

  if (row) return;

  const current = await env.DB.prepare(
    "SELECT last_sent_at_ms FROM partner_reminder_cooldowns WHERE cooldown_key = ?",
  )
    .bind(key)
    .first();
  const lastSentAtMs = Number(current && current.last_sent_at_ms);
  const retryAfterMs = Number.isFinite(lastSentAtMs)
    ? Math.max(1000, PARTNER_COOLDOWN_MS - (nowMs - lastSentAtMs))
    : PARTNER_COOLDOWN_MS;
  throw new HttpError(429, "Wait before reminding this person again.", {
    retryAfterSeconds: Math.ceil(retryAfterMs / 1000),
  });
}

async function releaseCooldown(env, key, nowMs) {
  await env.DB.prepare(
    "DELETE FROM partner_reminder_cooldowns WHERE cooldown_key = ? AND last_sent_at_ms = ?",
  )
    .bind(key, nowMs)
    .run();
}

async function sendOneSignal(recipientUserId, taskId, scopeId, reminderId, env) {
  const response = await upstreamFetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      authorization: `Key ${env.ONESIGNAL_REST_API_KEY}`,
      "content-type": "application/json; charset=utf-8",
    },
    body: JSON.stringify({
      app_id: env.ONESIGNAL_APP_ID,
      idempotency_key: reminderId,
      include_aliases: {external_id: [recipientUserId]},
      target_channel: "push",
      headings: {
        en: "Household reminder",
        pt: "Lembrete da casa",
      },
      contents: {
        en: "Your partner sent a reminder about your household task.",
        pt: "Seu parceiro enviou um lembrete sobre sua tarefa da casa.",
      },
      data: {
        type: "household_task_reminder",
        taskId,
        scopeId,
        kind: "partner",
      },
    }),
  });

  const raw = await response.text();
  let data = {};
  try {
    data = raw ? JSON.parse(raw) : {};
    if (!data || typeof data !== "object" || Array.isArray(data)) data = {};
  } catch (_) {
    data = {};
  }

  if (response.ok && !data.id && data.errors) {
    throw new HttpError(422, "Destinatário sem assinatura push disponível.", {code: "recipient_unavailable"});
  }
  if (!response.ok || typeof data.id !== "string" || !data.id || data.errors) {
    throw new HttpError(
      502,
      "Não foi possível entregar o lembrete ao OneSignal.",
      {code: "temporary_delivery_error"},
    );
  }
  return String(data.id);
}

async function handlePartnerReminder(request, env) {
  const idToken = bearerToken(request);
  const senderUserId = await firebaseUserId(idToken, env);
  const body = await request.json().catch(() => ({}));
  const reminderId = requireString(body?.reminderId, "reminderId").toLowerCase();
  const taskId = requireString(body?.taskId, "taskId");

  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(reminderId)) {
    throw new HttpError(400, "reminderId must be a UUID v4.");
  }

  const task = await loadTask(taskId, idToken, env);
  if (stringField(task, "status") !== "pending") {
    throw new HttpError(409, "Only pending tasks can be reminded.");
  }
  if (stringField(task, "scope") !== "shared") {
    throw new HttpError(409, "Partner reminders require a shared task.");
  }

  const scopeId = stringField(task, "scopeId");
  const members = sharedMembers(scopeId);
  if (members.length < 2 || `household:${[...new Set(members)].sort().join("|")}` !== scopeId || !members.includes(senderUserId)) {
    throw new HttpError(403, "The sender is not part of this household.");
  }

  const recipientUserId = stringField(task, "assigneeId");
  if (!recipientUserId || recipientUserId === senderUserId) {
    throw new HttpError(409, "The task must be assigned to another member.");
  }
  if (!members.includes(recipientUserId)) {
    throw new HttpError(409, "The assignee is not part of this household.");
  }

  await validateConnectedHousehold(
    senderUserId,
    recipientUserId,
    scopeId,
    idToken,
    env,
  );

  const nowMs = Date.now();
  // Reserve the identifier BEFORE delivery. Binding is immutable, including after
  // timeouts; never reuse an id for a different task, sender or recipient.
  await env.DB.prepare(`
    INSERT INTO partner_reminders
      (reminder_id, task_id, scope_id, sender_user_id, recipient_user_id, created_at_ms)
    VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(reminder_id) DO NOTHING
  `).bind(reminderId, taskId, scopeId, senderUserId, recipientUserId, nowMs).run();
  const existing = await env.DB.prepare(
    "SELECT * FROM partner_reminders WHERE reminder_id = ?",
  ).bind(reminderId).first();
  if (!existing || existing.task_id !== taskId || existing.scope_id !== scopeId ||
      existing.sender_user_id !== senderUserId || existing.recipient_user_id !== recipientUserId) {
    throw new HttpError(409, "Reminder identifier already belongs to another request.");
  }
  if (existing.onesignal_message_id) {
    return json(200, {ok: true, idempotent: true, messageId: existing.onesignal_message_id});
  }
  // OneSignal retains keys for 30 days. Never retry an ambiguous older send.
  if (nowMs - existing.created_at_ms >= 29 * 24 * 60 * 60 * 1000) {
    throw new HttpError(409, "Reminder retry window expired.");
  }
  const cooldownKey = `${taskId}|${senderUserId}|${recipientUserId}`;
  await acquireCooldown(
    env,
    cooldownKey,
    taskId,
    senderUserId,
    recipientUserId,
    nowMs,
  );

  try {
    const messageId = await sendOneSignal(
      recipientUserId,
      taskId,
      scopeId,
      reminderId,
      env,
    );

    await env.DB.prepare(
      "UPDATE partner_reminders SET onesignal_message_id = ? WHERE reminder_id = ?",
    ).bind(messageId, reminderId).run();

    return json(200, {ok: true, messageId});
  } catch (error) {
    await releaseCooldown(env, cooldownKey, nowMs);
    throw error;
  }
}

function validateEnvironment(env) {
  const required = [
    "FIREBASE_PROJECT_ID",
    "FIREBASE_WEB_API_KEY",
    "ONESIGNAL_APP_ID",
    "ONESIGNAL_REST_API_KEY",
  ];
  const missing = required.filter((key) => !String(env[key] || "").trim());
  if (missing.length > 0) {
    throw new HttpError(503, `Worker missing configuration: ${missing.join(", ")}`);
  }
  if (!env.DB) {
    throw new HttpError(503, "Worker missing D1 binding DB.");
  }
}

export default {
  async fetch(request, env) {
    try {
      validateEnvironment(env);
      const url = new URL(request.url);
      if (request.method === "GET" && url.pathname === "/health") {
        return json(200, {ok: true});
      }
      if (request.method === "POST" && url.pathname === "/household/reminders") {
        return await handlePartnerReminder(request, env);
      }
      return json(404, {error: "Not found."});
    } catch (error) {
      if (error instanceof HttpError) {
        return json(error.status, {error: error.message, ...error.details});
      }
      console.error("Unexpected reminder delivery failure.");
      return json(500, {error: "Unexpected reminder delivery failure."});
    }
  },
};
