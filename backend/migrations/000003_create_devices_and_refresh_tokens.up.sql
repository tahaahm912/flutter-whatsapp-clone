-- Migration: 000003_create_devices_and_refresh_tokens
--
-- These two tables were already part of the approved final schema
-- (Section 1: Identity & Auth) but hadn't been migrated yet, since
-- nothing needed them until now. POST /auth/login is the first
-- endpoint that actually requires session/device tracking, so this
-- migration brings them in verbatim from that schema — no redesign.

CREATE TABLE devices (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_name             VARCHAR(100),
    platform                VARCHAR(20) NOT NULL CHECK (platform IN ('android','ios','web','desktop')),
    push_token              TEXT,
    push_token_updated_at   TIMESTAMPTZ,
    status                  VARCHAR(20) NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active','revoked')),
    last_active_at          TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_devices_user ON devices(user_id);

CREATE TABLE refresh_tokens (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id           UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    token_hash          VARCHAR(255) NOT NULL,
    issued_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at          TIMESTAMPTZ NOT NULL,
    revoked_at          TIMESTAMPTZ
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE UNIQUE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
