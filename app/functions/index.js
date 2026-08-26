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

function tokenDocumentId(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function requireAuthenticatedUser(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return uid;
}

function requireToken(data) {
  const token = String((data && data.token) || "").trim();
  if (!token) {
    throw new HttpsError("invalid-argument", "A valid FCM token is required.");
  }
  return token;
}

exports.registerPushToken = onCall(async (request) => {
  const uid = requireAuthenticatedUser(request);
  const token = requireToken(request.data);
  const platform = String((request.data && request.data.platform) || "unknown").trim();

  await db
      .collection("users")
      .doc(uid)
      .collection(TOKEN_COLLECTION)
      .doc(tokenDocumentId(token))
      .set({
        token,
        platform,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

  return {ok: true};
});

exports.unregisterPushToken = onCall(async (request) => {
  const uid = requireAuthenticatedUser(request);
  const token = requireToken(request.data);

  await db
      .collection("users")
      .doc(uid)
      .collection(TOKEN_COLLECTION)
      .doc(tokenDocumentId(token))
      .delete();

  return {ok: true};
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

  if (reminder.kind === "partner") {
    return {
      title: "Lembrete da casa",
      body: `Não esqueça: ${taskTitle}`,
    };
  }

  return {
    title: "DuoSpend • Lembrete",
    body: taskTitle,
  };
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
      notification: {
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
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
    "every 1 minutes",
    async () => {
      const scheduled = await db
          .collection(REMINDERS)
          .where("status", "==", "scheduled")
          .limit(200)
          .get();

      const dueDocuments = scheduled.docs.filter((doc) => isDue(doc.data()));
      if (dueDocuments.length === 0) return;

      await Promise.all(dueDocuments.map(async (doc) => {
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
