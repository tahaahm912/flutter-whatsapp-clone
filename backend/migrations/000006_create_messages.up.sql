-- Migration: 000006_create_messages
--
-- Messages and message_recipients from the approved final schema
-- (Section 4). Only what Week 5's plaintext-first messaging actually
-- needs — message_media and group_sender_key_distributions stay for
-- whenever media messages / group chat are actually built.
--
-- IMPORTANT — read before touching message_recipients.ciphertext:
-- this column is NOT NULL by design, for real E2E encryption where
-- every recipient device gets its own independently-encrypted copy.
-- Week 5 is deliberately plaintext-first (per the build plan) — the
-- application layer writes plaintext into this column for now. This
-- requires NO schema change when Week 6 adds real encryption: the
-- column was always just TEXT, only what gets written into it
-- changes. See internal/messages/service.go for where that happens.

CREATE TABLE messages (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id     UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id           UUID NOT NULL REFERENCES users(id),
    sender_device_id    UUID NOT NULL REFERENCES devices(id),
    client_message_id   UUID NOT NULL,
    message_type        VARCHAR(10) NOT NULL DEFAULT 'text'
                        CHECK (message_type IN ('text','image','video','audio','file','system')),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at          TIMESTAMPTZ
);
-- Lets a client safely retry a send (e.g. after a lost response)
-- without risking a duplicate message: same device + same
-- client-generated ID = the same logical send attempt.
CREATE UNIQUE INDEX idx_message_client_dedup ON messages(sender_device_id, client_message_id);
CREATE INDEX idx_messages_conversation_time ON messages(conversation_id, created_at DESC);

CREATE TABLE message_recipients (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id          UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    recipient_user_id   UUID NOT NULL REFERENCES users(id),
    recipient_device_id UUID NOT NULL REFERENCES devices(id),
    ciphertext          TEXT NOT NULL,
    status              VARCHAR(10) NOT NULL DEFAULT 'sent'
                        CHECK (status IN ('sent','delivered','read')),
    delivered_at        TIMESTAMPTZ,
    read_at             TIMESTAMPTZ
);
CREATE UNIQUE INDEX idx_recipient_unique ON message_recipients(message_id, recipient_device_id);
CREATE INDEX idx_recipient_inbox ON message_recipients(recipient_device_id, status);
CREATE INDEX idx_recipient_undelivered ON message_recipients(recipient_user_id) WHERE status = 'sent';
