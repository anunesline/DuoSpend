const crypto = require("crypto");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getFunctions} = require("firebase-admin/functions");
const {getMessaging} = require("firebase-admin/messaging");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onTaskDispatched} = require("firebase-functions/tasks");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const adminFunctions = getFunctions();

const REMINDERS = "household_task_reminders";
const TASKS = "household_tasks";
const WALLETS = "wallets";
const TOKEN_COLLECTION = "fcm_tokens";
const COOLDOWNS = "household_reminder_cooldowns";
const PARTNER_COOLDOWN_MS = 2 * 60 * 60 * 1000;
const DELIVERY_LEASE_MS = 2 * 60 * 1000;
const MAX_DELIVERY_ATTEMPTS = 5;
const DISPATCH_FUNCTION = "dispatchHouseholdReminder";

function hash(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function requireAuthenticatedUser(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return uid;
}

function requireString(data, field) {
  const value = String((data && data[field]) || "").trim();
  if (!value) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return value;
}

function sharedMembers(scopeId) {
  if (!scopeId.startsWith("household:")) return [];
  return scopeId
      .substring("household:".length)
      .split("|")
      .map((value) => value.trim())
      .filter(Boolean);
}

async function validateConnectedHousehold(senderUserId, recipientUserId) {
  if (senderUserId === recipientUserId) return;

  const walletSnapshot = await db
      .collection(WALLETS)
      .where("memberIds", "array-contains", senderUserId)
      .get();

  const connected = walletSnapshot.docs.some((doc) => {
    const data = doc.data();
    if (String(data.type || "") !== "shared") return false;
    const members = Array.isArray(data.memberIds)
      ? data.memberIds.map((value) => String(value).trim())
      : [];
    return members.includes(senderUserId) && members.includes(recipientUserId);
  });

  if (!connected) {
    throw new HttpsError(
        "permission-denied",
        "The users are not connected in a shared household.",
    );
  }
}

exports.registerPushToken = onCall(async (request) => {
  const uid = requireAuthenticatedUser(request);
  const token = requireString(request.data, "token");
  const platform = String((request.data && request.data.platform) || "unknown").trim();

  await db
      .collection("users")
      .doc(uid)
      .collection(TOKEN_COLLECTION)
      .doc(hash(token))
      .set({
        token,
        platform,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

  return {ok: true};
});

exports.unregisterPushToken = onCall(async (request) => {
  const uid = requireAuthenticatedUser(request);
  const token = requireString(request.data, "token");

  await db
      .collection("users")
      .doc(uid)
      .collection(TOKEN_COLLECTION)
      .doc(hash(token))
      .delete();

  return {ok: true};
});

exports.getLatestHouseholdReminder = onCall(async (request) => {
  const uid = requireAuthenticatedUser(request);
  const taskId = requireString(request.data, "taskId");
  const recipientUserId = requireString(request.data, "recipientUserId");

  const snapshot = await db.collection(REMINDERS).where("taskId", "==", taskId).get();
  const matches = snapshot.docs
      .map((doc) => doc.data())
      .filter((item) =>
        item.senderUserId === uid && item.recipientUserId === recipientUserId)
      .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));

  return {reminder: matches.length > 0 ? matches[0] : null};
});

async function enqueueReminder(reminderId, remindAt) {
  const queue = adminFunctions.taskQueue(DISPATCH_FUNCTION);
  const options = {dispatchDeadlineSeconds: 60};
  if (remindAt.getTime() > Date.now()) {
    options.scheduleTime = remindAt;
  }
  await queue.enqueue({reminderId}, options);
}

async function releasePartnerCooldown(cooldownRef, expectedLastSentAt) {
  if (!cooldownRef) return;
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(cooldownRef);
    if (!snapshot.exists) return;
    if (String(snapshot.data().lastSentAt || "") === expectedLastSentAt) {
      transaction.delete(cooldownRef);
    }
  });
}

exports.createHouseholdReminder = onCall(async (request) => {
  const uid = requireAuthenticatedUser(request);
  const reminderId = requireString(request.data, "reminderId");
  const taskId = requireString(request.data, "taskId");

  const taskSnapshot = await db.collection(TASKS).doc(taskId).get();
  if (!taskSnapshot.exists) {
    throw new HttpsError("not-found", "Household task not found.");
  }

  const task = taskSnapshot.data();
  if (task.status !== "pending") {
    throw new HttpsError("failed-precondition", "Only pending tasks can be reminded.");
  }

  const scope = String(task.scope || "personal");
  const scopeId = String(task.scopeId || "");
  let recipientUserId;

  if (scope === "personal") {
    if (scopeId !== `user:${uid}`) {
      throw new HttpsError("permission-denied", "This personal task does not belong to the user.");
    }
    recipientUserId = uid;
  } else if (scope === "shared") {
    const members = sharedMembers(scopeId);
    if (!members.includes(uid)) {
      throw new HttpsError("permission-denied", "The user is not part of this household.");
    }
    recipientUserId = String(task.assigneeId || "").trim();
    if (!recipientUserId || !members.includes(recipientUserId)) {
      throw new HttpsError("failed-precondition", "The task needs a valid household assignee.");
    }
    await validateConnectedHousehold(uid, recipientUserId);
  } else {
    throw new HttpsError("failed-precondition", "Unsupported household task scope.");
  }

  const now = new Date();
  const nowIso = now.toISOString();
  const isPartnerReminder = recipientUserId !== uid;
  let remindAt = now;

  if (!isPartnerReminder) {
    const raw = request.data && request.data.remindAt;
    remindAt = raw ? new Date(String(raw)) : now;
    if (Number.isNaN(remindAt.getTime())) {
      throw new HttpsError("invalid-argument", "Invalid reminder date.");
    }
    if (remindAt.getTime() < now.getTime() - 30000) {
      throw new HttpsError("invalid-argument", "Reminder date cannot be in the past.");
    }
  }

  const reminder = {
    id: reminderId,
    taskId,
    scopeId,
    senderUserId: uid,
    recipientUserId,
    kind: isPartnerReminder ? "partner" : "self",
    status: remindAt.getTime() > now.getTime() ? "scheduled" : "pendingDelivery",
    remindAt: remindAt.toISOString(),
    createdAt: nowIso,
    deliveredAt: null,
    deliveryAttempts: 0,
  };

  const reminderRef = db.collection(REMINDERS).doc(reminderId);
  let cooldownRef = null;

  if (!isPartnerReminder) {
    const existing = await reminderRef.get();
    if (existing.exists) {
      throw new HttpsError("already-exists", "Reminder already exists.");
    }
    await reminderRef.set(reminder);
  } else {
    cooldownRef = db.collection(COOLDOWNS).doc(
        hash(`${taskId}|${uid}|${recipientUserId}`),
    );

    await db.runTransaction(async (transaction) => {
      const reminderSnapshot = await transaction.get(reminderRef);
      if (reminderSnapshot.exists) {
        throw new HttpsError("already-exists", "Reminder already exists.");
      }

      const cooldownSnapshot = await transaction.get(cooldownRef);
      if (cooldownSnapshot.exists) {
        const lastSentAt = new Date(String(cooldownSnapshot.data().lastSentAt || ""));
        if (!Number.isNaN(lastSentAt.getTime())) {
          const elapsed = now.getTime() - lastSentAt.getTime();
          if (elapsed < PARTNER_COOLDOWN_MS) {
            const retryAfterSeconds = Math.ceil((PARTNER_COOLDOWN_MS - elapsed) / 1000);
            throw new HttpsError(
                "resource-exhausted",
                "Wait before reminding this person again.",
                {retryAfterSeconds},
            );
          }
        }
      }

      transaction.set(cooldownRef, {
        taskId,
        senderUserId: uid,
        recipientUserId,
        lastSentAt: nowIso,
      });
      transaction.set(reminderRef, reminder);
    });
  }

  try {
    await enqueueReminder(reminderId, remindAt);
  } catch (error) {
    await reminderRef.set({
      status: "failed",
      failureReason: "queue-enqueue-failed",
      failedAt: new Date().toISOString(),
    }, {merge: true});
    await releasePartnerCooldown(cooldownRef, nowIso);
    throw new HttpsError("internal", "Could not schedule reminder delivery.");
  }

  return {reminder};
});

async function claimReminder(reference) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) return {state: "missing"};

    const data = snapshot.data();
    if (
      data.status === "delivered" ||
      data.status === "failed" ||
      data.status === "cancelled"
    ) {
      return {state: "terminal"};
    }

    const now = new Date();
    const previousLease = data.deliveryStartedAt
      ? new Date(String(data.deliveryStartedAt))
      : null;
    if (
      previousLease &&
      !Number.isNaN(previousLease.getTime()) &&
      now.getTime() - previousLease.getTime() < DELIVERY_LEASE_MS
    ) {
      return {state: "busy"};
    }

    const attempt = Number(data.deliveryAttempts || 0) + 1;
    transaction.update(reference, {
      status: "pendingDelivery",
      deliveryStartedAt: now.toISOString(),
      deliveryAttempts: attempt,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {state: "claimed", reminder: data, attempt};
  });
}

async function releaseDeliveryLease(reference, reason) {
  await reference.set({
    status: "pendingDelivery",
    deliveryStartedAt: FieldValue.delete(),
    lastDeliveryError: String(reason || "transient-delivery-error"),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

async function markFailed(reference, reason) {
  await reference.set({
    status: "failed",
    deliveryStartedAt: FieldValue.delete(),
    failureReason: reason,
    failedAt: new Date().toISOString(),
  }, {merge: true});
}

async function getRecipientTokens(userId) {
  const snapshot = await db
      .collection("users")
      .doc(userId)
      .collection(TOKEN_COLLECTION)
      .get();

  return snapshot.docs
      .map((doc) => ({reference: doc.ref, token: doc.data().token}))
      .filter((item) => typeof item.token === "string" && item.token.length > 0);
}

async function buildNotification(reminder) {
  const taskSnapshot = await db.collection(TASKS).doc(reminder.taskId).get();
  const taskTitle = taskSnapshot.exists && taskSnapshot.data().title
    ? String(taskSnapshot.data().title)
    : "Tarefa da casa";

  return reminder.kind === "partner"
    ? {title: "Lembrete da casa", body: `Não esqueça: ${taskTitle}`}
    : {title: "DuoSpend • Lembrete", body: taskTitle};
}

function isTransientMessagingCode(code) {
  return code === "messaging/internal-error" ||
    code === "messaging/server-unavailable" ||
    code === "messaging/quota-exceeded" ||
    code === "messaging/message-rate-exceeded" ||
    code === "messaging/device-message-rate-exceeded";
}

async function deliverReminder(reference, reminder, attempt) {
  const recipientUserId = String(reminder.recipientUserId || "").trim();
  if (!recipientUserId) {
    await markFailed(reference, "missing-recipient");
    return;
  }

  const tokenRecords = await getRecipientTokens(recipientUserId);
  if (tokenRecords.length === 0) {
    if (attempt < MAX_DELIVERY_ATTEMPTS) {
      throw new Error("no-device-token-yet");
    }
    await markFailed(reference, "no-device-token");
    return;
  }

  const notification = await buildNotification(reminder);
  const response = await messaging.sendEachForMulticast({
    tokens: tokenRecords.map((item) => item.token),
    notification,
    data: {
      type: "household_task_reminder",
      reminderId: reference.id,
      taskId: String(reminder.taskId || ""),
      scopeId: String(reminder.scopeId || ""),
      kind: String(reminder.kind || "self"),
    },
    android: {
      priority: "high",
      notification: {priority: "high"},
    },
    apns: {
      payload: {aps: {sound: "default"}},
    },
  });

  const invalidTokenRefs = [];
  let hasTransientFailure = false;
  response.responses.forEach((result, index) => {
    if (result.success) return;
    const code = result.error && result.error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      invalidTokenRefs.push(tokenRecords[index].reference);
    } else if (isTransientMessagingCode(code)) {
      hasTransientFailure = true;
    }
  });
  await Promise.all(invalidTokenRefs.map((ref) => ref.delete()));

  if (response.successCount > 0) {
    await reference.set({
      status: "delivered",
      deliveredAt: new Date().toISOString(),
      deliveryStartedAt: FieldValue.delete(),
      failureReason: FieldValue.delete(),
      lastDeliveryError: FieldValue.delete(),
    }, {merge: true});
    return;
  }

  if (hasTransientFailure && attempt < MAX_DELIVERY_ATTEMPTS) {
    throw new Error("transient-fcm-delivery-error");
  }

  await markFailed(reference, "fcm-delivery-failed");
}

exports.dispatchHouseholdReminder = onTaskDispatched(
    {
      retryConfig: {
        maxAttempts: MAX_DELIVERY_ATTEMPTS,
        minBackoffSeconds: 30,
      },
      rateLimits: {
        maxConcurrentDispatches: 20,
      },
    },
    async (request) => {
      const reminderId = String((request.data && request.data.reminderId) || "").trim();
      if (!reminderId) return;

      const reminderRef = db.collection(REMINDERS).doc(reminderId);
      const claim = await claimReminder(reminderRef);
      if (claim.state === "missing" || claim.state === "terminal") return;
      if (claim.state === "busy") {
        throw new Error("Reminder delivery is already in progress.");
      }

      try {
        await deliverReminder(reminderRef, claim.reminder, claim.attempt);
      } catch (error) {
        await releaseDeliveryLease(reminderRef, error && error.message);
        throw error;
      }
    },
);
