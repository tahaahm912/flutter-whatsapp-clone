-- Rollback for 000006_create_messages
-- Order matters: message_recipients references messages.

DROP TABLE IF EXISTS message_recipients;
DROP TABLE IF EXISTS messages;
