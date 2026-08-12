-- Rollback for 000005_create_conversations
-- Order matters: conversation_participants references conversations.

DROP TABLE IF EXISTS conversation_participants;
DROP TABLE IF EXISTS conversations;
