const crypto = require("crypto");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

const REMINDERS = "household_task_reminders";
const TASKS = "household_tasks";
const TOKEN_COLLECTION = "fcm_tokens";
const COOLDOWNS = "household_reminder_cooldowns";
const PARTNER_COOLDOWN_MS = 2 * 60 * 60 * 1000;

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
  } else {
    throw new HttpsError("failed-precondition", "Unsupported household task scope.");
  }

  const now = new Date();
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
    createdAt: now.toISOString(),
    deliveredAt: null,
  };

  const reminderRef = db.collection(REMINDERS).doc(reminderId);

  if (!isPartnerReminder) {
    await reminderRef.set(reminder);
    return {reminder};
  }

  const cooldownRef = db.collection(COOLDOWNS).doc(
      hash(`${taskId}|${uid}|${recipientUserId}`),
  );

  await db.runTransaction(async (transaction) => {
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
      lastSentAt: now.toISOString(),
    });
    transaction.set(reminderRef, reminder);
  });

  return {reminder};
});

function isDue(reminder, now = new Date()) {
  const value = reminder.remindAt;
  if (!value) return true;
  const due = new Date(value);
  return !Number.isNaN(due.getTime()) && due.getTime() <= now.getTime();
}

async function claimReminder(reference, expectedStatus) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) return null;

    const data = snapshot.data();
    if (data.status !== expectedStatus || data.deliveryStartedAt) {
      return null;
    }

    if (expectedStatus === "scheduled" && !isDue(data)) {
      return null;
    }

    transaction.update(reference, {
      status: "pendingDelivery",
      deliveryStartedAt: new Date().toISOString(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return data;
  });
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

async function deliverReminder(reference, reminder) {
  const recipientUserId = String(reminder.recipientUserId || "").trim();
  if (!recipientUserId) {
    await reference.update({
      status: "failed",
      failureReason: "missing-recipient",
      failedAt: new Date().toISOString(),
    });
    return;
  }

  const tokenRecords = await getRecipientTokens(recipientUserId);
  if (tokenRecords.length === 0) {
    await reference.update({
      status: "failed",
      failureReason: "no-device-token",
      failedAt: new Date().toISOString(),
    });
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
  response.responses.forEach((result, index) => {
    if (result.success) return;
    const code = result.error && result.error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      invalidTokenRefs.push(tokenRecords[index].reference);
    }
  });
  await Promise.all(invalidTokenRefs.map((ref) => ref.delete()));

  if (response.successCount === 0) {
    await reference.update({
      status: "failed",
      failureReason: "fcm-delivery-failed",
      failedAt: new Date().toISOString(),
    });
    return;
  }

  await reference.update({
    status: "delivered",
    deliveredAt: new Date().toISOString(),
    failureReason: FieldValue.delete(),
  });
}

exports.deliverHouseholdReminder = onDocumentCreated(
    `${REMINDERS}/{reminderId}`,
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) return;
      const reminder = snapshot.data();
      if (reminder.status !== "pendingDelivery") return;

      const claimed = await claimReminder(snapshot.ref, "pendingDelivery");
      if (!claimed) return;
      await deliverReminder(snapshot.ref, claimed);
    },
);

exports.processScheduledHouseholdReminders = onSchedule(
    "* * * * *",
    async () => {
      const nowIso = new Date().toISOString();
      const scheduled = await db
          .collection(REMINDERS)
          .where("status", "==", "scheduled")
          .where("remindAt", "<=", nowIso)
          .orderBy("remindAt")
          .limit(200)
          .get();

      await Promise.all(scheduled.docs.map(async (doc) => {
        const claimed = await claimReminder(doc.ref, "scheduled");
        if (!claimed) return;
        try {
          await deliverReminder(doc.ref, claimed);
        } catch (error) {
          logger.error("Failed to deliver scheduled household reminder", {
            reminderId: doc.id,
            error,
          });
          await doc.ref.update({
            status: "failed",
            failureReason: "unexpected-delivery-error",
            failedAt: new Date().toISOString(),
          });
        }
      }));
    },
);
