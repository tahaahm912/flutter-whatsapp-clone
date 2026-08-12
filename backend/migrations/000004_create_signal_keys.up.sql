-- Migration: 000004_create_signal_keys
--
-- These three tables were part of the approved final schema (Section
-- 2: Signal Protocol Key Management) from the very first schema
-- design, but hadn't been migrated yet since nothing needed them
-- until today. Added verbatim, no redesign — same pattern as
-- migration 000003 for devices/refresh_tokens.

-- One identity key per device (not per user) — required for
-- multi-device (V7) later; each device has its own long-term identity
-- key pair, only the public half is ever stored here.
CREATE TABLE signal_identity_keys (
    device_id           UUID PRIMARY KEY REFERENCES devices(id) ON DELETE CASCADE,
    identity_public_key TEXT NOT NULL,
    registration_id     INTEGER NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Signed pre-key: rotated periodically. History is kept (old rows
-- marked is_active = false), not overwritten, via the app-level
-- rotation logic in internal/keys — never deleted here directly.
CREATE TABLE signal_signed_prekeys (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id           UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    key_id              INTEGER NOT NULL,
    public_key          TEXT NOT NULL,
    signature           TEXT NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_signed_prekey_device_key ON signal_signed_prekeys(device_id, key_id);
CREATE INDEX idx_signed_prekey_active ON signal_signed_prekeys(device_id) WHERE is_active;

-- One-time pre-keys: a genuine repeating group (dozens per device,
-- consumed one-at-a-time as other users start conversations with this
-- device) — hence its own table with an is_used flag.
CREATE TABLE signal_one_time_prekeys (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id           UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    key_id              INTEGER NOT NULL,
    public_key          TEXT NOT NULL,
    is_used             BOOLEAN NOT NULL DEFAULT false,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    used_at             TIMESTAMPTZ
);
CREATE UNIQUE INDEX idx_otpk_device_key ON signal_one_time_prekeys(device_id, key_id);
CREATE INDEX idx_otpk_available ON signal_one_time_prekeys(device_id) WHERE NOT is_used;
