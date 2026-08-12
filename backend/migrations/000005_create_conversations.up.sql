-- Migration: 000005_create_conversations
--
-- Conversations and participants from the approved final schema
-- (Section 3). Only the two tables Week 5's plaintext-first messaging
-- actually needs are added now — group_details and
-- conversation_read_state stay for whenever group chat / unread
-- counts are actually built, same incremental-migration approach as
-- every prior week.

CREATE TABLE conversations (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type                VARCHAR(10) NOT NULL CHECK (type IN ('direct','group')),
    created_by          UUID NOT NULL REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE conversation_participants (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id     UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role                VARCHAR(10) NOT NULL DEFAULT 'member' CHECK (role IN ('member','admin')),
    joined_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    left_at             TIMESTAMPTZ,
    is_active           BOOLEAN NOT NULL DEFAULT true
);
CREATE UNIQUE INDEX idx_participant_unique ON conversation_participants(conversation_id, user_id);
CREATE INDEX idx_participant_user ON conversation_participants(user_id) WHERE is_active;
