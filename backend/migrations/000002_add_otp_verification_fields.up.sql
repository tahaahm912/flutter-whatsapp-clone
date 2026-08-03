-- Migration: 000002_add_otp_verification_fields
--
-- Additive change on top of 000001_create_users_table. Registration
-- (Week 2, Day 1) creates an account that isn't usable yet; OTP
-- verification (Week 2, Day 2) is what activates it. The original
-- users table didn't model a pre-verification state, so this adds:
--   1. A new 'pending_verification' value for account_status
--      (the new default for freshly registered accounts).
--   2. phone_verified_at / email_verified_at timestamps, so we know
--      *when* (and whether) each identifier was actually confirmed.

ALTER TABLE users DROP CONSTRAINT users_account_status_check;

ALTER TABLE users ALTER COLUMN account_status SET DEFAULT 'pending_verification';

ALTER TABLE users ADD CONSTRAINT users_account_status_check
    CHECK (account_status IN ('pending_verification','active','deactivated','banned'));

ALTER TABLE users ADD COLUMN phone_verified_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN email_verified_at TIMESTAMPTZ;
