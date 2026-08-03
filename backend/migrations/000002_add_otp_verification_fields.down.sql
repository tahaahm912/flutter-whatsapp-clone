-- Rollback for 000002_add_otp_verification_fields

ALTER TABLE users DROP COLUMN IF EXISTS email_verified_at;
ALTER TABLE users DROP COLUMN IF EXISTS phone_verified_at;

ALTER TABLE users DROP CONSTRAINT users_account_status_check;
ALTER TABLE users ALTER COLUMN account_status SET DEFAULT 'active';
ALTER TABLE users ADD CONSTRAINT users_account_status_check
    CHECK (account_status IN ('active','deactivated','banned'));
