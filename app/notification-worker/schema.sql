CREATE TABLE IF NOT EXISTS partner_reminder_cooldowns (
  cooldown_key TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  sender_user_id TEXT NOT NULL,
  recipient_user_id TEXT NOT NULL,
  last_sent_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS partner_reminders (
  reminder_id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  scope_id TEXT NOT NULL,
  sender_user_id TEXT NOT NULL,
  recipient_user_id TEXT NOT NULL,
  created_at_ms INTEGER NOT NULL,
  onesignal_message_id TEXT
);

CREATE INDEX IF NOT EXISTS idx_partner_reminders_lookup
  ON partner_reminders(task_id, sender_user_id, recipient_user_id, created_at_ms);
