-- Migration: 000001_create_users_table
-- Matches the `users` table exactly as defined in the project's
-- finalized database schema (whatsapp_clone_schema.sql, Section 1).

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- provides gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS citext;     -- case-insensitive email column

CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number        VARCHAR(20)  UNIQUE,
    email               CITEXT       UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    name                VARCHAR(100) NOT NULL,
    profile_photo_url   TEXT,
    about_text          VARCHAR(150),
    account_status      VARCHAR(20)  NOT NULL DEFAULT 'active'
                        CHECK (account_status IN ('active','deactivated','banned')),
    last_seen_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_identifier_present CHECK (phone_number IS NOT NULL OR email IS NOT NULL)
);

CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_email ON users(email);
